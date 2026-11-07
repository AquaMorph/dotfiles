#!/usr/bin/env python3
"""Sync endpoint models into a chezmoi OpenCode source template without applying it."""

import argparse
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import tempfile
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


def resolve_setting(value):
    """Resolve OpenCode's environment substitutions without exposing credentials."""
    if not isinstance(value, str):
        raise ValueError("endpoint and credential settings must be strings")

    def replace(match):
        name = match.group(1)
        if not os.environ.get(name):
            raise ValueError("required environment variable is unset: " + name)
        return os.environ[name]

    return re.sub(r"\{env:([^}]+)\}", replace, value)


def fetch_models(provider):
    settings = provider.get("settings", {})
    base_url = resolve_setting(settings.get("baseURL", "")).rstrip("/")
    if not base_url.startswith(("https://", "http://")):
        raise ValueError("provider settings.baseURL must be an HTTP(S) URL")
    api_key = resolve_setting(settings.get("apiKey", ""))
    if not api_key:
        for name in provider.get("env", []) + ["AQUAAI_KEY"]:
            if os.environ.get(name):
                api_key = os.environ[name]
                break

    headers = {"Accept": "application/json"}
    headers.update({key: resolve_setting(value)
                    for key, value in provider.get("headers", {}).items()})
    if api_key:
        headers["Authorization"] = "Bearer " + api_key
    request = Request(base_url + "/models", headers=headers)
    with urlopen(request, timeout=30) as response:
        payload = json.load(response)
    if not isinstance(payload, dict) or not isinstance(payload.get("data"), list):
        raise ValueError("model endpoint must return an object containing a data array")
    model_ids = set()
    for model in payload["data"]:
        if not isinstance(model, dict) or not isinstance(model.get("id"), str):
            raise ValueError("model endpoint returned an entry without a string id")
        if not model["id"].strip():
            raise ValueError("model endpoint returned an empty model id")
        model_ids.add(model["id"])
    return model_ids


def add_models(provider, model_ids):
    models = provider.setdefault("models", {})
    if not isinstance(models, dict):
        raise ValueError("provider models must be an object")
    # An alias already represents its upstream model; do not add a duplicate.
    represented = set(models)
    for model_id, model in models.items():
        if not isinstance(model, dict):
            raise ValueError("each configured model must be an object")
        represented.add(model.get("modelID", model_id))
    added = sorted(model_ids - represented)
    for model_id in added:
        models[model_id] = {"name": model_id}
    return added


def read_template(text):
    """Protect unquoted template values so JSON edits never persist rendered secrets."""
    expressions = {}
    pieces = []
    position = 0
    quoted = False
    escaped = False
    while position < len(text):
        if text.startswith("{{", position):
            match = re.match(r'{{(?:"(?:\\.|[^"\\])*"|`[^`]*`|[^"`}])*}}',
                             text[position:])
            if not match:
                raise ValueError("unsupported or unterminated template expression")
            expression = match.group()
            if quoted:
                raise ValueError("template expressions inside JSON strings are not supported")
            marker = "__OPENCODE_TEMPLATE_VALUE_" + str(len(expressions)) + "__"
            if marker in text:
                raise ValueError("template contains a reserved placeholder")
            expressions[marker] = expression
            pieces.append(json.dumps(marker))
            position += len(expression)
            continue
        character = text[position]
        pieces.append(character)
        if escaped:
            escaped = False
        elif quoted and character == "\\":
            escaped = True
        elif character == '"':
            quoted = not quoted
        position += 1
    try:
        config = json.loads("".join(pieces))
    except ValueError:
        raise ValueError("template must be JSON with template expressions only as values") from None
    return config, expressions


def chezmoi_output(*arguments, input_text=None):
    result = subprocess.run(["chezmoi", *arguments], input=input_text,
                            capture_output=True, text=True, check=False)
    if result.returncode:
        # Rendering diagnostics can include secrets; do not echo subprocess output.
        raise ValueError("chezmoi " + arguments[0] + " failed; check chezmoi/password-manager access")
    return result.stdout


def write_config(path, original, config, expressions):
    """Replace atomically, preserving permissions and detecting intervening edits."""
    mode = stat.S_IMODE(path.stat().st_mode)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", dir=path.parent,
                                         prefix=".opencode-models-", delete=False) as output:
            temporary = Path(output.name)
            os.chmod(temporary, mode)
            text = json.dumps(config, indent=2, ensure_ascii=True) + "\n"
            for marker, expression in expressions.items():
                text = text.replace(json.dumps(marker), expression)
            output.write(text)
        if path.read_bytes() != original:
            raise ValueError("config changed during sync; retry with the latest config")
        os.replace(temporary, path)
    finally:
        if temporary is not None and temporary.exists():
            temporary.unlink()


def main():
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--template", type=Path,
                        help="source template (default: chezmoi source-path for OpenCode config)")
    parser.add_argument("--provider", default="AquaAI", help="provider ID (default: AquaAI)")
    parser.add_argument("--dry-run", action="store_true", help="list additions without writing")
    args = parser.parse_args()
    try:
        template = args.template
        if template is None:
            target = config_home / "opencode" / "opencode.json"
            template = Path(chezmoi_output("source-path", str(target)).strip())
        path = template.expanduser().resolve(strict=True)
        original = path.read_bytes()
        text = original.decode("utf-8")
        config, expressions = read_template(text)
        try:
            rendered = json.loads(chezmoi_output("execute-template", input_text=text))
        except ValueError:
            raise ValueError("could not render template as JSON; check chezmoi/password-manager access") from None
        if not isinstance(config, dict):
            raise ValueError("config must be a JSON object")
        provider = config.get("providers", {}).get(args.provider)
        if not isinstance(provider, dict):
            raise ValueError("provider is not defined in this config: " + args.provider)
        rendered_provider = rendered.get("providers", {}).get(args.provider)
        if not isinstance(rendered_provider, dict):
            raise ValueError("provider is not defined in rendered config: " + args.provider)
        if provider.get("models", {}) != rendered_provider.get("models", {}):
            raise ValueError("templated model definitions are not supported; keep models as plain JSON")
        added = add_models(provider, fetch_models(rendered_provider))
        if added and not args.dry_run:
            write_config(path, original, config, expressions)
        verb = "Would add" if args.dry_run else "Added"
        print(f"{verb} {len(added)} model(s) for {args.provider}.")
        for model_id in added:
            print("  " + model_id)
        return 0
    except HTTPError as error:
        print(f"opencode-sync-models: model endpoint returned HTTP {error.code}", file=sys.stderr)
    except URLError:
        print("opencode-sync-models: could not reach model endpoint", file=sys.stderr)
    except (OSError, ValueError) as error:
        # Do not print response bodies or request headers, which can contain secrets.
        message = str(error) if not isinstance(error, json.JSONDecodeError) else "invalid JSON response"
        print("opencode-sync-models: " + message, file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())

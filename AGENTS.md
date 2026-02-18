# AGENTS.md - Coding Guidelines for Agentic Operations

This repository is a personal dotfiles collection managed with [chezmoi](https://www.chezmoi.io). It contains configuration files, shell scripts, and Python utilities for system management.

## Build, Lint & Test Commands

### Running Scripts
- **Shell scripts**: `bash ./home/bin/executable_<script_name>.sh` or run directly if executable
- **Python scripts**: `python3 ./home/bin/<script_name>.py`
- **Install dependencies**: `pip install -r requirements.txt`

### Testing
No formal test framework is present. Validation is done by:
- Running scripts manually with test inputs
- Checking for runtime errors (e.g., `python3 -m py_compile <file>` for syntax)
- Verifying command outputs match expected behavior

### Single Test/Script Execution
```bash
# Run a single Python script
python3 ./home/bin/i3-mouse.py

# Run a single shell script
bash ./home/bin/executable_update.sh

# Check Python syntax without running
python3 -m py_compile ./home/bin/homeassistant.py
```

## Code Style Guidelines

### Python

#### Imports
- Use standard library imports first, then third-party imports, then local imports
- Import order: `os`, `sys`, `time` → `requests`, `i3ipc`, `pyautogui` → local modules
- Each import on its own line (avoid `import x, y, z`)
- Example:
  ```python
  #!/usr/bin/env python3
  import os
  import sys
  import datetime
  from requests import get, post
  import json
  ```

#### Naming Conventions
- **Functions**: `snake_case` (e.g., `getPoints()`, `pointsToDirection()`)
- **Classes**: `PascalCase` (e.g., `HomeAssistant`, `Direction`)
- **Constants**: `UPPER_SNAKE_CASE`
- **Private members**: prefix with underscore `_privateVar`
- Enums use `PascalCase` for class and `UPPER_SNAKE_CASE` for members

#### Formatting
- Use 4-space indentation (not tabs)
- Line length: Keep to reasonable length (~80-100 chars) where practical
- Shebang for executable scripts: `#!/usr/bin/env python3`
- Blank lines: 2 between top-level definitions, 1 between method definitions

#### Types & Documentation
- No type hints required (not present in codebase)
- Add docstring comments for classes and non-obvious functions
- Comment format: `# description` (no colons at end unless explaining)
- Example: `# Enum for mouse direction`

#### Error Handling
- Use `raise` for exceptions in API wrappers (e.g., `response.raise_for_status()`)
- Return `None` for optional/conditional operations
- Handle command availability checks: `if command -v <cmd> &> /dev/null`

### Shell Scripts

#### Shebang & Headers
- Start with: `#!/bin/bash`
- Add brief comment: `# Script purpose description`

#### Formatting
- Use 2-space indentation
- Quote variables: `"${variable}"` or `"$variable"`
- Use `function name { ... }` syntax for functions

#### Naming & Structure
- Function names: `snake_case`
- Variables: lowercase with underscores for clarity
- Check for command availability before use:
  ```bash
  if command -v <cmd> &> /dev/null; then
      <cmd> <args>
  fi
  ```

#### Error Handling
- Use `set -e` to exit on error when appropriate
- Check command exit status: `if <command>; then ... fi`
- Redirect stderr appropriately: `2>/dev/null` or `2>&1`

### Configuration Files
- Before generating a commit, always consult `agents/COMMITS.md` for the required style.

#### chezmoi Templates
- Dotfiles use chezmoi's templating system
- Template syntax: `{{ }}` for variables (Chezmoi specific)
- File naming: `dot_` prefix for dotfiles (e.g., `dot_zshrc`)
- Executable scripts: `executable_` prefix

#### Comments
- Use `#` for all config file comments
- Keep comments concise and descriptive

## Repository Patterns

### Commit Message Format
Follow conventional commits style (all lowercase).
- `feat(scope): description` - New feature
- `fix(scope): description` - Bug fix
- `refactor(scope): description` - Code refactoring
- `docs(scope): description` - Documentation changes
- Example: `feat(zsh): update dotfiles` or `fix(scripts): use correct pass entry`

#### Pushing Remotes
- **Do not push git repositories to remote unless explicitly instructed.**

### File Organization
- Shell scripts: `home/bin/executable_<name>.sh`
- Python scripts: `home/bin/<name>.py`
- Config files: `home/dot_config/<app>/` (following XDG spec)
- Dependencies: List in `requirements.txt`

## Key Dependencies

- **configparser** - Config file parsing
- **todoist-python** - Todoist API
- **tbapy** - TBA API for robotics
- **holidays** - Holiday detection
- **i3ipc** - i3 window manager control
- **pyautogui** - Mouse control
- **requests** - HTTP library
- **dateutil** - Date utilities

## Development Notes

- This is a personal configuration repository, not a library
- Scripts are system-level utilities and automation scripts
- No CI/CD pipeline present (manual validation)
- Target OS: Linux (Ubuntu/Fedora compatible)
- Python version: Python 3.x minimum

#!/bin/bash
# Start the Quickshell bar on the current Wayland session.

qs -c bar kill 2>/dev/null || true
qs -c bar --daemonize

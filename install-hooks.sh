#!/bin/sh

ln -sf "${1:-$PWD}/check-commit.sh" .git/hooks/commit-msg

echo "Installed hooks at $PWD!"

#!/bin/bash

ln -sf "${1:$PWD}/check_commit.sh" .git/hooks/commit-msg

echo "Installed hooks at $PWD!"

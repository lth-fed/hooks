#!/usr/bin/env bash

VALID_MODULES="INFRA|API|DB|AUTH|APP|ADMIN"
VALID_ACTIONS="Update|Refactor|Bug|Docs"

# $1 can be file, or checks last commit

git_log_commit_msg=$(git log -1 --format="%s")
file_commit_msg=$([[ -n "${1:-""}" ]] && cat "$1")
commit_msg="${file_commit_msg:-$git_log_commit_msg}"

echo "Checking: \"$commit_msg\""
echo

set -euo pipefail

errors=()

# Check overall format: [MODULE(s)] (Action): Message
if ! grep -qP "^\[($VALID_MODULES)(-($VALID_MODULES))*\] \(($VALID_ACTIONS)\): .+$" <<< "$commit_msg"; then
    # Give specific feedback rather than just "invalid format"
    if ! grep -qP "^\[" <<< "$commit_msg"; then
        errors+=("Missing module prefix. Expected format: [MODULE] (Action): Message")
    elif ! grep -qP ":" <<< "$commit_msg"; then
        errors+=("Missing colon. Expected format: [MODULE] (Action): Message")
    elif ! grep -qP "^\[[A-Z-]+\]" <<< "$commit_msg"; then
        errors+=("Module section malformed. Expected: [MODULE] or [MODULE1-MODULE2]")
    else
        # Extract and validate module(s)
        module_part=$(grep -oP '(?<=\[)[^\]]+(?=\])' <<< "$commit_msg")
        IFS='-' read -ra modules <<< "$module_part"
        for mod in "${modules[@]}"; do
            if ! grep -qP "^($VALID_MODULES)$" <<< "$mod"; then
                errors+=("Unknown module '$mod'. Valid modules: INFRA, API, DB, AUTH, APP, ADMIN")
            fi
        done

        # Extract and validate action
        if ! grep -qP "\] \(($VALID_ACTIONS)\): " <<< "$commit_msg"; then
            action_part=$(grep -oP '(?<=\() [^)]+(?=\))' <<< "$commit_msg" | head -1 || echo "")
            if [[ -z "$action_part" ]]; then
                errors+=("Missing or malformed action. Expected format: (Action) — one of: Update, Refactor, Bug, Docs")
            else
                errors+=("Unknown action '${action_part# }'. Valid actions: Update, Refactor, Bug, Docs")
            fi
        fi

        # Check message exists after ": "
        if ! grep -qP ":\s+\S+" <<< "$commit_msg"; then
            errors+=("Missing message after ': '")
        fi
    fi
fi

if [[ ${#errors[@]} -gt 0 ]]; then
    echo "FAIL: commit message does not follow the convention."
    for err in "${errors[@]}"; do
        echo "  • $err"
    done
    echo
    echo "Convention:  [MODULE] (Action): Message in imperative form"
    echo "Modules:     INFRA, API, DB, AUTH, APP, ADMIN  (combine with '-' for multi-module)"
    echo "Actions:     Update, Refactor, Bug, Docs"
    echo "Example:     [API-DB] (Refactor): Extract shared error types into common module"
    echo
    echo "See https://docs.teknologappen.se/commit-messages/ for more info"
    exit 1
fi

echo "OK: commit message follows the convention."

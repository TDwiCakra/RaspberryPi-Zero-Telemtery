#!/bin/bash
# =============================================================================
# connect_tmux.sh — Telemetry Session Manager
#
# - First user to connect becomes ADMIN (read/write)
# - Subsequent users become VIEWER (read-only)
# - Requires password to connect (edit PASSWORD below before deploying)
# =============================================================================

SESSION="telemetry"
PASSWORD="YOUR PASSWORD"   # ← CHANGE THIS before deploying

# Prompt for session password
read -s -p "Enter Telemetry Password: " INPUT
echo ""

if [ "$INPUT" != "$PASSWORD" ]; then
    echo "Wrong password. Access denied."
    exit 1
fi

# Create session if it doesn't exist yet
tmux has-session -t "$SESSION" 2>/dev/null
if [ $? != 0 ]; then
    tmux new-session -d -s "$SESSION"
    echo "New telemetry session created."
fi

# Count active clients
CLIENTS=$(tmux list-clients -t "$SESSION" 2>/dev/null | wc -l)

if [ "$CLIENTS" -eq 0 ]; then
    echo "You are ADMIN (read/write)"
    tmux attach -t "$SESSION"
else
    echo "You are VIEWER (read-only)"
    tmux attach -r -t "$SESSION"
fi

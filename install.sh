#!/usr/bin/env bash
# ecs install script - one command to install embedded-code-skill
set -euo pipefail

SKILL_DIR="${HOME}/.workbuddy/skills/embedded-code-skill"
REPO_URL="https://raw.githubusercontent.com/leon-2050/embedded-code-skill/main"

echo "Installing embedded-code-skill to ${SKILL_DIR}..."

mkdir -p "${SKILL_DIR}"

# Download single-entry SKILL.md
curl -sf "${REPO_URL}/SKILL.md" -o "${SKILL_DIR}/SKILL.md"

if [ ! -s "${SKILL_DIR}/SKILL.md" ]; then
    echo "Error: Failed to download SKILL.md" >&2
    exit 1
fi

echo "Done! The skill is installed at ${SKILL_DIR}/SKILL.md"
echo "Usage: /ecs <command> [args]"
echo "  /ecs generate  - Generate driver skeleton"
echo "  /ecs rewrite   - Clean up legacy code"
echo "  /ecs review    - Review for risks"
echo "  /ecs install   - Adapt rules for IDE/agent"

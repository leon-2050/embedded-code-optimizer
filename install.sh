#!/usr/bin/env bash
# ecs install script - one command to install embedded-code-skill
set -euo pipefail

SKILL_DIR="${HOME}/.claude/skills/ecs"
TMP_DIR=$(mktemp -d)
REPO_URL="https://raw.githubusercontent.com/leon-2050/embedded-code-skill/main"

echo "Installing ecs skill to ${SKILL_DIR}..."

mkdir -p "${SKILL_DIR}"

# Download main SKILL.md
curl -sf "${REPO_URL}/SKILL.md" -o "${SKILL_DIR}/SKILL.md"

# Download sub-skills
for subskill in embedded-code-skill-standards embedded-code-skill-drivers embedded-code-skill-arch embedded-code-skill-domains; do
  mkdir -p "${SKILL_DIR}/${subskill}"
  curl -sf "${REPO_URL}/${subskill}/SKILL.md" -o "${SKILL_DIR}/${subskill}/SKILL.md"
done

# Download validation
mkdir -p "${SKILL_DIR}/validation"
curl -sf "${REPO_URL}/validation/check-consistency.sh" -o "${SKILL_DIR}/validation/check-consistency.sh"

echo "Done! Run /ecs to use the skill."

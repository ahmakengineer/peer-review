#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
GLOBAL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --global) GLOBAL=true; shift ;;
        *) echo "Usage: $0 [--global]"; exit 1 ;;
    esac
done

install_to() {
    local parent="$1" agent="$2"
    local dest="$parent/peer-review"
    mkdir -p "$parent"
    if [[ -d "$dest" ]]; then
        echo "  [SKIP] $agent — already installed at $dest"
    else
        cp -r "$SKILL_DIR" "$dest"
        echo "  [ OK ] $agent — installed to $dest"
    fi
}

installed=0
found=0

if $GLOBAL; then
    for entry in \
        "$HOME/.claude/skills:Claude Code" \
        "$HOME/.config/opencode/skills:OpenCode" \
        "$HOME/.agents/skills:Codex CLI" \
        "$HOME/.gemini/skills:Gemini CLI" \
        "$HOME/.copilot/skills:GitHub Copilot"; do
        parent="${entry%%:*}"
        agent="${entry##*:}"
        if [[ -d "$parent" ]]; then
            ((found++))
            install_to "$parent" "$agent"
            ((installed++))
        fi
    done
else
    for entry in \
        ".claude/skills:Claude Code" \
        ".cursor/skills:Cursor" \
        ".windsurf/skills:Windsurf" \
        ".opencode/skills:OpenCode" \
        ".agents/skills:Codex CLI" \
        ".gemini/skills:Gemini CLI" \
        ".github/skills:GitHub Copilot"; do
        parent="${entry%%:*}"
        agent="${entry##*:}"
        if [[ -d "$parent" ]]; then
            ((found++))
            install_to "$parent" "$agent"
            ((installed++))
        fi
    done
fi

if [[ $found -eq 0 ]]; then
    scope="project"
    $GLOBAL && scope="per-user"
    echo "No $scope agent directories found. Create one and re-run, or use --global for per-user install."
else
    echo "Done. $installed installed."
fi

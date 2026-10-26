#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
: "${HOME:?HOME must be set}"

paths=(
  .pi/agent/extensions
  .pi/agent/prompts
  .pi/agent/mcp.json
  .pi/agent/AGENTS.md
  .pi/agent/settings.json
  .zshrc
  .skhdrc
  .gitignore
  .gitconfig
  .config/ghostty
  .config/nvim
  .config/starship
  .agents/skills
)

for path in "${paths[@]}"; do
  source_path="$REPO_DIR/$path"
  target_path="$HOME/$path"

  if [[ ! -e "$source_path" ]]; then
    printf 'Skipping missing source: %s\n' "$source_path" >&2
    continue
  fi

  if [[ -L "$target_path" && "$(readlink "$target_path")" == "$source_path" ]]; then
    printf 'Already linked: %s\n' "$target_path"
    continue
  fi

  mkdir -p -- "$(dirname -- "$target_path")"

  # Preserve existing files, directories, and dangling symlinks.
  if [[ -e "$target_path" || -L "$target_path" ]]; then
    backup_path="${target_path}.backup.$(date +%Y%m%d%H%M%S)"
    suffix=0
    while [[ -e "$backup_path" || -L "$backup_path" ]]; do
      suffix=$((suffix + 1))
      backup_path="${target_path}.backup.$(date +%Y%m%d%H%M%S).$suffix"
    done
    mv -- "$target_path" "$backup_path"
    printf 'Backed up: %s -> %s\n' "$target_path" "$backup_path"
  fi

  ln -s -- "$source_path" "$target_path"
  printf 'Linked: %s -> %s\n' "$target_path" "$source_path"
done

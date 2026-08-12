#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PLUGIN_ROOT="${REPO_ROOT}/plugins/codex-terminal"
MARKETPLACE_PATH="${REPO_ROOT}/.agents/plugins/marketplace.json"
MANIFEST_PATH="${PLUGIN_ROOT}/.codex-plugin/plugin.json"
AGENT_PATH="${PLUGIN_ROOT}/skills/control-codex-terminal/agents/openai.yaml"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

find_validator_root() {
  local candidate
  for candidate in \
    "${CODEX_SKILLS_ROOT:-}" \
    "${CODEX_HOME:-}/skills/.system" \
    "${HOME}/.codex/skills/.system"; do
    if [[ -n "${candidate}" && -f "${candidate}/plugin-creator/scripts/validate_plugin.py" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  return 1
}

find_yaml_python() {
  local candidate
  for candidate in \
    "${CODEX_PYTHON:-}" \
    "${HOME}/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3" \
    "$(command -v python3)"; do
    if [[ -n "${candidate}" && -x "${candidate}" ]] && \
      "${candidate}" -c 'import yaml' >/dev/null 2>&1; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  return 1
}

validate_metadata_alignment() {
  python3 - "${MARKETPLACE_PATH}" "${MANIFEST_PATH}" <<'PY'
import json
import sys
from pathlib import Path

marketplace = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
manifest = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
plugins = marketplace.get("plugins", [])
assert len(plugins) == 1, "marketplace must contain exactly one plugin"
entry = plugins[0]
assert marketplace.get("name") == "codex-terminal-local"
assert entry.get("name") == manifest.get("name") == "codex-terminal"
assert entry.get("source", {}).get("path") == "./plugins/codex-terminal"
assert entry.get("policy", {}).get("installation") == "AVAILABLE"
assert entry.get("policy", {}).get("authentication") == "ON_INSTALL"
assert entry.get("category") == manifest.get("interface", {}).get("category")
PY

  ruby -rjson -ryaml -e '
    manifest = JSON.parse(File.read(ARGV[0]))
    agent = YAML.safe_load(File.read(ARGV[1]), aliases: false)
    abort "display name mismatch" unless manifest.dig("interface", "displayName") == agent.dig("interface", "display_name")
    abort "short description mismatch" unless manifest.dig("interface", "shortDescription") == agent.dig("interface", "short_description")
  ' "${MANIFEST_PATH}" "${AGENT_PATH}"
}

scan_repository() {
  local placeholder_pattern='\[TO''DO:|\bT''BD\b'
  local secret_pattern='BEGIN [A-Z ]*PRIVATE KEY|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]+'

  if rg -n "${placeholder_pattern}" "${REPO_ROOT}" \
    --glob '!scripts/validate.sh'; then
    echo "Placeholder marker found." >&2
    exit 1
  fi

  if rg -l "${secret_pattern}" "${REPO_ROOT}" \
    --hidden --glob '!.git/**' --glob '!scripts/validate.sh'; then
    echo "Potential sensitive material found in the files listed above." >&2
    exit 1
  fi

  if rg -n '/Users/[^/]+/|/home/[^/]+/' "${REPO_ROOT}" \
    --hidden --glob '!.git/**' --glob '!scripts/validate.sh'; then
    echo "Machine-specific path found." >&2
    exit 1
  fi

  if rg -n '"(composerIcon|logo|logoDark)"[[:space:]]*:[[:space:]]*"https?://|data:image/[^;]+;base64' \
    "${MARKETPLACE_PATH}" "${MANIFEST_PATH}" "${PLUGIN_ROOT}/assets"; then
    echo "External or base64 metadata artwork found." >&2
    exit 1
  fi
}

run_official_validators() {
  local validator_root
  local python_bin

  if ! validator_root="$(find_validator_root)"; then
    echo "Official Codex validator skills not found; portable checks completed."
    return 0
  fi
  if ! python_bin="$(find_yaml_python)"; then
    echo "Official validators found, but no Python interpreter with PyYAML is available." >&2
    echo "Set CODEX_PYTHON to a compatible interpreter and run this script again." >&2
    exit 1
  fi

  "${python_bin}" "${validator_root}/plugin-creator/scripts/validate_plugin.py" "${PLUGIN_ROOT}"
  "${python_bin}" "${validator_root}/skill-creator/scripts/quick_validate.py" \
    "${PLUGIN_ROOT}/skills/control-codex-terminal"
}

main() {
  require_command python3
  require_command ruby
  require_command xmllint
  require_command rg

  python3 -m json.tool "${MARKETPLACE_PATH}" >/dev/null
  python3 -m json.tool "${MANIFEST_PATH}" >/dev/null
  ruby -e 'require "yaml"; YAML.safe_load(File.read(ARGV[0]), aliases: false)' "${AGENT_PATH}"
  xmllint --noout "${PLUGIN_ROOT}"/assets/*.svg
  validate_metadata_alignment
  scan_repository
  run_official_validators

  if git -C "${REPO_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "${REPO_ROOT}" diff --check
  fi

  echo "Repository validation passed."
}

main "$@"

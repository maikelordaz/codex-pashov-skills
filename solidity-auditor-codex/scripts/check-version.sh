#!/usr/bin/env bash
set -euo pipefail

skill_root=""
check_remote="false"
remote_version_url="https://raw.githubusercontent.com/pashov/skills/main/solidity-auditor/VERSION"
timeout_seconds="5"
as_json="false"

json_escape() {
  local value="$1"
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}
  printf '%s' "$value"
}

while (($# > 0)); do
  case "$1" in
    --skill-root)
      skill_root="$2"
      shift 2
      ;;
    --check-remote)
      check_remote="true"
      shift
      ;;
    --remote-url)
      remote_version_url="$2"
      shift 2
      ;;
    --timeout-seconds)
      timeout_seconds="$2"
      shift 2
      ;;
    --json)
      as_json="true"
      shift
      ;;
    --help|-h)
      cat <<'EOF'
Usage: check-version.sh [--skill-root PATH] [--check-remote] [--remote-url URL] [--timeout-seconds N] [--json]
EOF
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$skill_root" ]]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  skill_root="$(cd "$script_dir/.." && pwd -P)"
else
  skill_root="$(cd "$skill_root" && pwd -P)"
fi

local_version_path="$skill_root/VERSION"
local_version=""
remote_version=""
remote_status="skipped"
status="local-missing"
update_available="false"
message="Local VERSION file not found."

if [[ -f "$local_version_path" ]]; then
  local_version="$(tr -d '\r\n' < "$local_version_path")"
  status="local-only"
  message="Local version loaded."
fi

if [[ "$check_remote" == "true" ]]; then
  if command -v curl >/dev/null 2>&1; then
    if remote_version="$(curl -fsSL --max-time "$timeout_seconds" "$remote_version_url" 2>/dev/null)"; then
      remote_status="ok"
      remote_version="${remote_version//$'\r'/}"
      remote_version="${remote_version//$'\n'/}"
      if [[ -z "$local_version" ]]; then
        status="local-missing"
        message="Remote version loaded, but local VERSION is missing."
      elif [[ "$remote_version" == "$local_version" ]]; then
        status="up-to-date"
        message="Local version matches the remote version."
      else
        status="outdated"
        update_available="true"
        message="A newer upstream version is available."
      fi
    else
      remote_status="unavailable"
      if [[ -n "$local_version" ]]; then
        status="remote-unavailable"
        message="Remote version check failed. Continue without blocking."
      else
        message="Remote version check failed and local VERSION is missing."
      fi
    fi
  else
    remote_status="unavailable"
    if [[ -n "$local_version" ]]; then
      status="remote-unavailable"
      message="curl is unavailable. Continue without blocking."
    else
      message="curl is unavailable and local VERSION is missing."
    fi
  fi
fi

if [[ "$as_json" == "true" ]]; then
  printf '{\n'
  printf '  "skill_root": "%s",\n' "$(json_escape "$skill_root")"
  printf '  "local_version_path": "%s",\n' "$(json_escape "$local_version_path")"
  if [[ -n "$local_version" ]]; then
    printf '  "local_version": "%s",\n' "$(json_escape "$local_version")"
  else
    printf '  "local_version": null,\n'
  fi
  if [[ -n "$remote_version" ]]; then
    printf '  "remote_version": "%s",\n' "$(json_escape "$remote_version")"
  else
    printf '  "remote_version": null,\n'
  fi
  printf '  "remote_checked": %s,\n' "$check_remote"
  printf '  "remote_status": "%s",\n' "$(json_escape "$remote_status")"
  printf '  "status": "%s",\n' "$(json_escape "$status")"
  printf '  "update_available": %s,\n' "$update_available"
  printf '  "message": "%s"\n' "$(json_escape "$message")"
  printf '}\n'
else
  printf 'status=%s\n' "$status"
  if [[ -n "$local_version" ]]; then
    printf 'local=%s\n' "$local_version"
  fi
  if [[ -n "$remote_version" ]]; then
    printf 'remote=%s\n' "$remote_version"
  fi
  printf 'message=%s\n' "$message"
fi

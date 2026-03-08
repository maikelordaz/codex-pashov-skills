#!/usr/bin/env bash
set -euo pipefail

repo_root="."
mode="default"
output_dir=""
include_excluded="false"
attack_vectors_path=""
as_json="false"
declare -a target_files=()

json_escape() {
  local value="$1"
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}
  printf '%s' "$value"
}

make_temp_dir() {
  local candidate=""

  for candidate in "${TMPDIR:-}" "${TEMP:-}" "${TMP:-}"; do
    if [[ -n "$candidate" && -d "$candidate" ]]; then
      mktemp -d "${candidate%/}/solidity-auditor-codex.XXXXXX"
      return 0
    fi
  done

  mktemp -d
}

resolve_optional_path() {
  local path="$1"
  local base="$2"

  if [[ -z "$path" ]]; then
    return 1
  fi

  if [[ -f "$path" ]]; then
    (
      cd "$(dirname "$path")"
      printf '%s/%s\n' "$(pwd -P)" "$(basename "$path")"
    )
    return 0
  fi

  if [[ -f "$base/$path" ]]; then
    (
      cd "$(dirname "$base/$path")"
      printf '%s/%s\n' "$(pwd -P)" "$(basename "$base/$path")"
    )
    return 0
  fi

  printf 'Attack vector file not found: %s\n' "$path" >&2
  exit 1
}

while (($# > 0)); do
  case "$1" in
    --repo-root)
      repo_root="$2"
      shift 2
      ;;
    --mode)
      mode="$2"
      shift 2
      ;;
    --output-dir)
      output_dir="$2"
      shift 2
      ;;
    --file)
      target_files+=("$2")
      shift 2
      ;;
    --include-excluded)
      include_excluded="true"
      shift
      ;;
    --attack-vectors)
      attack_vectors_path="$2"
      shift 2
      ;;
    --json)
      as_json="true"
      shift
      ;;
    --help|-h)
      cat <<'EOF'
Usage: build-audit-input.sh [--repo-root PATH] [--mode MODE] [--output-dir PATH] [--file PATH ...] [--include-excluded] [--attack-vectors PATH] [--json]
EOF
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
skill_root="$(cd "$script_dir/.." && pwd -P)"
repo_root="$(cd "$repo_root" && pwd -P)"

discover_cmd=(bash "$script_dir/discover-solidity-files.sh" --repo-root "$repo_root")
if [[ "$include_excluded" == "true" ]]; then
  discover_cmd+=(--include-excluded)
fi
for file in "${target_files[@]}"; do
  discover_cmd+=(--file "$file")
done

mapfile -t relative_files < <("${discover_cmd[@]}")
if ((${#relative_files[@]} == 0)); then
  printf 'No in-scope Solidity files found.\n' >&2
  exit 1
fi

if [[ -z "$output_dir" ]]; then
  output_dir="$(make_temp_dir)"
else
  mkdir -p "$output_dir"
  output_dir="$(cd "$output_dir" && pwd -P)"
fi

policy_path="$skill_root/AGENTS.md"
report_template_path="$skill_root/templates/audit-report-template.md"
vector_scan_path="$skill_root/docs/worker-playbooks/vector-scan.md"
adversarial_path="$skill_root/docs/worker-playbooks/adversarial-reasoning.md"
resolved_attack_vectors_path=""
if [[ -n "$attack_vectors_path" ]]; then
  resolved_attack_vectors_path="$(resolve_optional_path "$attack_vectors_path" "$skill_root/docs/attack-vectors")"
fi

bundle_path="$output_dir/audit-input.md"
manifest_path="$output_dir/manifest.json"

{
  printf '# Solidity Audit Input Bundle\n\n'
  printf -- '- Generated at: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf -- '- Mode: %s\n' "$mode"
  printf -- '- Repo root: %s\n' "$repo_root"
  printf -- '- File count: %s\n' "${#relative_files[@]}"
  printf -- '- Policy path: %s\n' "$policy_path"
  printf -- '- Report template path: %s\n' "$report_template_path"
  if [[ -n "$resolved_attack_vectors_path" ]]; then
    printf -- '- Attack vectors path: %s\n' "$resolved_attack_vectors_path"
  fi
  printf '\n## Files In Scope\n\n'
  for relative_path in "${relative_files[@]}"; do
    printf -- '- `%s`\n' "$relative_path"
  done
  printf '\n## Persistent Policy\n\n'
  cat "$policy_path"
  printf '\n\n## Report Template\n\n'
  cat "$report_template_path"
  if [[ -n "$resolved_attack_vectors_path" ]]; then
    printf '\n\n## Selected Attack Vectors\n\n'
    cat "$resolved_attack_vectors_path"
  fi
  printf '\n\n## Playbook References\n\n'
  printf -- '- Vector scan playbook: `%s`\n' "$vector_scan_path"
  printf -- '- Adversarial reasoning playbook: `%s`\n' "$adversarial_path"
  printf '\n## Solidity Sources\n\n'
  for relative_path in "${relative_files[@]}"; do
    absolute_path="$repo_root/$relative_path"
    printf '### %s\n\n' "$relative_path"
    printf '```solidity\n'
    cat "$absolute_path"
    printf '\n```\n\n'
  done
} > "$bundle_path"

{
  printf '{\n'
  printf '  "repo_root": "%s",\n' "$(json_escape "$repo_root")"
  printf '  "mode": "%s",\n' "$(json_escape "$mode")"
  printf '  "output_dir": "%s",\n' "$(json_escape "$output_dir")"
  printf '  "bundle_path": "%s",\n' "$(json_escape "$bundle_path")"
  printf '  "policy_path": "%s",\n' "$(json_escape "$policy_path")"
  printf '  "report_template_path": "%s",\n' "$(json_escape "$report_template_path")"
  if [[ -n "$resolved_attack_vectors_path" ]]; then
    printf '  "attack_vectors_path": "%s",\n' "$(json_escape "$resolved_attack_vectors_path")"
  else
    printf '  "attack_vectors_path": null,\n'
  fi
  printf '  "file_count": %s,\n' "${#relative_files[@]}"
  printf '  "files": [\n'
  for index in "${!relative_files[@]}"; do
    printf '    "%s"' "$(json_escape "${relative_files[$index]}")"
    if (( index + 1 < ${#relative_files[@]} )); then
      printf ','
    fi
    printf '\n'
  done
  printf '  ]\n'
  printf '}\n'
} > "$manifest_path"

if [[ "$as_json" == "true" ]]; then
  cat "$manifest_path"
else
  printf '%s\n' "$bundle_path"
fi

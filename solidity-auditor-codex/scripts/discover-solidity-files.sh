#!/usr/bin/env bash
set -euo pipefail

repo_root="."
include_excluded="false"
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

resolve_path() {
  local path="$1"
  if [[ "$path" != /* ]]; then
    path="$repo_root/$path"
  fi

  if [[ ! -e "$path" ]]; then
    printf 'Path not found: %s\n' "$1" >&2
    exit 1
  fi

  (
    cd "$(dirname "$path")"
    printf '%s/%s\n' "$(pwd -P)" "$(basename "$path")"
  )
}

relative_to_repo() {
  local path="$1"
  local prefix="${repo_root%/}/"
  if [[ "$path" == "$prefix"* ]]; then
    printf '%s\n' "${path#"$prefix"}"
  else
    printf '%s\n' "$path"
  fi
}

is_excluded() {
  local relative_path="$1"
  local normalized_path="${relative_path//\\//}"
  local file_name="${normalized_path##*/}"

  if [[ "$include_excluded" == "true" ]]; then
    return 1
  fi

  case "/$normalized_path/" in
    */interfaces/*|*/lib/*|*/mocks/*|*/test/*)
      return 0
      ;;
  esac

  case "$file_name" in
    *.t.sol|*Test*.sol|*Mock*.sol)
      return 0
      ;;
  esac

  return 1
}

while (($# > 0)); do
  case "$1" in
    --repo-root)
      repo_root="$2"
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
    --json)
      as_json="true"
      shift
      ;;
    --help|-h)
      cat <<'EOF'
Usage: discover-solidity-files.sh [--repo-root PATH] [--file PATH ...] [--include-excluded] [--json]
EOF
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

repo_root="$(cd "$repo_root" && pwd -P)"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
skill_root="$(cd "$script_dir/.." && pwd -P)"

docs_root="$skill_root/docs"
templates_root="$skill_root/templates"
assets_root="$skill_root/assets"

declare -a discovered_paths=()
if ((${#target_files[@]} > 0)); then
  for file in "${target_files[@]}"; do
    resolved_file="$(resolve_path "$file")"
    if [[ "$resolved_file" != *.sol ]]; then
      printf 'Target file is not a Solidity file: %s\n' "$file" >&2
      exit 1
    fi
    discovered_paths+=("$resolved_file")
  done
else
  if command -v rg >/dev/null 2>&1; then
    while IFS= read -r entry; do
      [[ -z "$entry" ]] && continue
      if [[ "$entry" != /* ]]; then
        entry="$repo_root/$entry"
      fi
      discovered_paths+=("$(resolve_path "$entry")")
    done < <(rg --files "$repo_root" -g '*.sol')
  else
    while IFS= read -r entry; do
      discovered_paths+=("$entry")
    done < <(find "$repo_root" -type f -name '*.sol' | sort -u)
  fi
fi

mapfile -t unique_paths < <(printf '%s\n' "${discovered_paths[@]}" | awk 'NF' | sort -u)

declare -a relative_files=()
declare -a absolute_files=()
for absolute_path in "${unique_paths[@]}"; do
  relative_path="$(relative_to_repo "$absolute_path")"
  if ! is_excluded "$relative_path"; then
    relative_files+=("${relative_path//\\//}")
    absolute_files+=("$absolute_path")
  fi
done

if [[ "$as_json" == "true" ]]; then
  printf '{\n'
  printf '  "repo_root": "%s",\n' "$(json_escape "$repo_root")"
  if ((${#target_files[@]} > 0)); then
    printf '  "mode": "targeted",\n'
  else
    printf '  "mode": "repo",\n'
  fi
  printf '  "include_excluded": %s,\n' "$include_excluded"
  printf '  "reference_paths": {\n'
  printf '    "skill_root": "%s",\n' "$(json_escape "$skill_root")"
  printf '    "scripts_root": "%s",\n' "$(json_escape "$script_dir")"
  printf '    "docs_root": "%s",\n' "$(json_escape "$docs_root")"
  printf '    "attack_vectors_root": "%s",\n' "$(json_escape "$docs_root/attack-vectors")"
  printf '    "templates_root": "%s",\n' "$(json_escape "$templates_root")"
  printf '    "report_template_path": "%s",\n' "$(json_escape "$templates_root/audit-report-template.md")"
  printf '    "assets_root": "%s",\n' "$(json_escape "$assets_root")"
  printf '    "docs_assets_root": "%s",\n' "$(json_escape "$assets_root/docs")"
  printf '    "findings_root": "%s",\n' "$(json_escape "$assets_root/findings")"
  printf '    "version_path": "%s"\n' "$(json_escape "$skill_root/VERSION")"
  printf '  },\n'
  printf '  "file_count": %s,\n' "${#relative_files[@]}"
  printf '  "files": [\n'
  for index in "${!relative_files[@]}"; do
    printf '    {"relative_path": "%s", "absolute_path": "%s"}' \
      "$(json_escape "${relative_files[$index]}")" \
      "$(json_escape "${absolute_files[$index]}")"
    if (( index + 1 < ${#relative_files[@]} )); then
      printf ','
    fi
    printf '\n'
  done
  printf '  ]\n'
  printf '}\n'
else
  printf '%s\n' "${relative_files[@]}"
fi

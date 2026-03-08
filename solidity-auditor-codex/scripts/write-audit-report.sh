#!/usr/bin/env bash
set -euo pipefail

repo_root="."
project_name=""
timestamp="$(date '+%Y%m%d-%H%M%S')"
input_path=""
output_path=""
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
    --repo-root)
      repo_root="$2"
      shift 2
      ;;
    --project-name)
      project_name="$2"
      shift 2
      ;;
    --timestamp)
      timestamp="$2"
      shift 2
      ;;
    --input)
      input_path="$2"
      shift 2
      ;;
    --output-path)
      output_path="$2"
      shift 2
      ;;
    --json)
      as_json="true"
      shift
      ;;
    --help|-h)
      cat <<'EOF'
Usage: write-audit-report.sh [--repo-root PATH] [--project-name NAME] [--timestamp YYYYMMDD-HHMMSS] [--input FILE] [--output-path FILE] [--json]
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

if [[ -z "$project_name" ]]; then
  project_name="$(basename "$repo_root")"
fi

findings_dir="$skill_root/assets/findings"
template_path="$skill_root/templates/audit-report-template.md"
mkdir -p "$findings_dir"

if [[ -z "$output_path" ]]; then
  output_path="$findings_dir/${project_name}-pashov-ai-audit-report-${timestamp}.md"
fi

mkdir -p "$(dirname "$output_path")"

content_source="template"
if [[ -n "$input_path" ]]; then
  cat "$input_path" > "$output_path"
  content_source="file"
elif [[ ! -t 0 ]]; then
  cat > "$output_path"
  content_source="stdin"
else
  cat "$template_path" > "$output_path"
fi

if [[ "$as_json" == "true" ]]; then
  printf '{\n'
  printf '  "repo_root": "%s",\n' "$(json_escape "$repo_root")"
  printf '  "project_name": "%s",\n' "$(json_escape "$project_name")"
  printf '  "output_path": "%s",\n' "$(json_escape "$output_path")"
  printf '  "content_source": "%s"\n' "$(json_escape "$content_source")"
  printf '}\n'
else
  printf '%s\n' "$output_path"
fi

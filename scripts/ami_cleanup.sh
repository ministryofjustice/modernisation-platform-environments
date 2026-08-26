# scripts/ami_cleanup.sh
#!/usr/bin/env bash
set -euo pipefail

# ami_cleanup.sh
# Finds unused AMIs you own, applies age gates (months or minute test-mode),
# optionally excludes AMIs referenced in code (-c), writes:
#   - ami_candidates.csv
#   - ami_commands.sh (deregister commands with --delete-associated-snapshots)
#   - ami_snapshots.csv (ami_id,snapshot_id) for fallback deletes
# If -d (dry-run) is set, commands are written but not executed.

# ------------------------
# Defaults / args
# ------------------------
APP_NAME=""
OUT_CMDS="ami_commands.sh"
EXCLUDE_CODE_REFS=0
MONTHS=3
DRY_RUN=0
TEST_MODE=0
AGE_MINUTES=10
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-eu-west-2}}"

usage() {
  cat <<EOF
Usage: $0 [-a <application>] [-s <commands_file>] [-c] [-m <months>] [-d] [--test-mode --age-minutes N] [delete]

Options:
  -a <application>    Application name (used when -c to search repo for AMI refs).
  -s <file>           Output commands file (default: ami_commands.sh).
  -c                  Exclude AMIs referenced in code (best-effort grep).
  -m <months>         Minimum age in months (default: 3). Ignored if --test-mode.
  -d                  Dry-run (write commands only; do not execute).
  --test-mode         Use minute-based age gate (intended for CI tests).
  --age-minutes N     Age minutes threshold when --test-mode is set (default: 10).

Notes:
- Writes ami_candidates.csv and ami_snapshots.csv next to commands file.
- Deregistration commands include --delete-associated-snapshots.
EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -a) APP_NAME="$2"; shift 2 ;;
    -s) OUT_CMDS="$2"; shift 2 ;;
    -c) EXCLUDE_CODE_REFS=1; shift ;;
    -m) MONTHS="$2"; shift 2 ;;
    -d) DRY_RUN=1; shift ;;
    --test-mode) TEST_MODE=1; shift ;;
    --age-minutes) AGE_MINUTES="$2"; shift 2 ;;
    delete) shift ;; # tolerated/no-op (for backwards compat in callers)
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

command -v jq >/dev/null 2>&1 || { echo "jq is required"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "aws cli is required"; exit 1; }

# ------------------------
# Light AWS retry (polish #3)
# ------------------------
aws_retry() {
  # aws_retry <ec2 ...> OR <service ...> (call like: aws_retry ec2 describe-images ...)
  local max=5 delay=2 attempt=1
  while true; do
    aws "$@" && return 0
    code=$?
    if (( attempt >= max )); then
      echo "AWS command failed after ${attempt} attempts: aws $*" >&2
      return $code
    fi
    sleep $delay
    delay=$((delay*2))
    attempt=$((attempt+1))
  done
}

# Outputs
OUT_CSV="ami_candidates.csv"
OUT_MAP="ami_snapshots.csv"

: > "${OUT_CMDS}"
: > "${OUT_CSV}"
: > "${OUT_MAP}"

# Header rows
echo "ImageId,OwnerId,CreationDate,Public,Name" >> "${OUT_CSV}"
echo "ami_id,snapshot_id" >> "${OUT_MAP}"

# ------------------------
# Helper: ISO to epoch
# ------------------------
iso_to_epoch() {
  # input like 2025-11-05T18:15:05.000Z
  date -u -d "${1}" +%s 2>/dev/null || python3 - <<PY || ruby -e "require 'time'; puts Time.parse('${1}').to_i"
import sys,datetime
print(int(datetime.datetime.fromisoformat("${1}".replace('Z','+00:00')).timestamp()))
PY
}

now_epoch="$(date -u +%s)"

# ------------------------
# Build "referenced in code" sets (when -c)
# ------------------------
declare -A referenced_ids
declare -A referenced_names

if [[ "${EXCLUDE_CODE_REFS}" -eq 1 ]]; then
  search_paths=(".")
  if [[ -n "${APP_NAME}" ]]; then
    if [[ -d "terraform/environments/${APP_NAME}" ]]; then
      search_paths=("terraform/environments/${APP_NAME}")
    fi
  fi

  while IFS= read -r -d '' tf; do
    while read -r id; do
      [[ -n "$id" ]] && referenced_ids["$id"]=1
    done < <(grep -Eo 'ami\s*=\s*"(ami-[0-9a-f]+)"' "$tf" | sed -E 's/.*"(ami-[0-9a-f]+)".*/\1/' | sort -u)

    while read -r nm; do
      [[ -n "$nm" ]] && referenced_names["$nm"]=1
    done < <(grep -Eo 'ami_name\s*=\s*"([^"]+)"' "$tf" | sed -E 's/.*"([^"]+)".*/\1/' | sort -u)
  done < <(find "${search_paths[@]}" -type f -name "*.tf" -print0 2>/dev/null || true)
fi

# ------------------------
# Determine age threshold
# ------------------------
use_minutes_gate=0
if [[ "${TEST_MODE}" -eq 1 ]]; then
  use_minutes_gate=1
  min_age_seconds=$(( AGE_MINUTES * 60 ))
else
  min_age_seconds=$(( MONTHS * 30 * 24 * 3600 ))
fi

if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo "[PREVIEW] Scanning AMIs in ${REGION} (dry-run; no deletion)"
else
  echo "[LIVE] Collecting candidates and deregistering (if any)"
fi

echo "Effective AMI test flags: $([[ ${use_minutes_gate} -eq 1 ]] && echo --test-mode --age-minutes ${AGE_MINUTES} || echo "<none>")"
echo "----------------------------------------------------"

# ------------------------
# Discover AMIs you own
# ------------------------
images_json="$(aws_retry ec2 describe-images --region "${REGION}" --owners self)"
image_count="$(jq '.Images | length' <<< "${images_json}")"

# Helper: check if AMI is in use by any instance
is_ami_in_use() {
  local ami_id="$1"
  local used
  used="$(aws_retry ec2 describe-instances --region "${REGION}" \
            --filters "Name=image-id,Values=${ami_id}" \
            --query 'Reservations[].Instances[].InstanceId' --output text 2>/dev/null || true)"
  [[ -n "${used}" ]]
}

candidates=()

for idx in $(seq 0 $((image_count-1))); do
  ami_id="$(jq -r ".Images[${idx}].ImageId" <<< "${images_json}")"
  name="$(jq -r ".Images[${idx}].Name // \"\"" <<< "${images_json}")"
  creation="$(jq -r ".Images[${idx}].CreationDate" <<< "${images_json}")"
  public="$(jq -r ".Images[${idx}].Public" <<< "${images_json}")"
  owner="$(jq -r ".Images[${idx}].OwnerId" <<< "${images_json}")"

  created_epoch="$(iso_to_epoch "${creation}")"
  age_sec=$(( now_epoch - created_epoch ))
  if [[ "${age_sec}" -lt "${min_age_seconds}" ]]; then
    continue
  fi

  if [[ "${EXCLUDE_CODE_REFS}" -eq 1 ]]; then
    if [[ -n "${referenced_ids[${ami_id}]:-}" || -n "${referenced_names[${name}]:-}" ]]; then
      continue
    fi
  fi

  if is_ami_in_use "${ami_id}"; then
    continue
  fi

  echo "${ami_id},${owner},${creation},${public},${name}" >> "${OUT_CSV}"
  candidates+=("${ami_id}")

  snaps="$(jq -r ".Images[${idx}].BlockDeviceMappings[]?.Ebs?.SnapshotId // empty" <<< "${images_json}" | sort -u || true)"
  if [[ -n "${snaps}" ]]; then
    while read -r s; do
      [[ -z "${s}" ]] && continue
      echo "${ami_id},${s}" >> "${OUT_MAP}"
    done <<< "${snaps}"
  fi
done

# ------------------------
# Generate deregister commands (with --delete-associated-snapshots)
# ------------------------
if [[ "${#candidates[@]}" -eq 0 ]]; then
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "[PREVIEW] No AMIs found matching cleanup filters."
  else
    echo "[LIVE] No AMIs found matching the deletion criteria."
  fi
  exit 0
fi

for ami in "${candidates[@]}"; do
  echo "aws ec2 deregister-image --image-id ${ami} --region ${REGION} --delete-associated-snapshots" >> "${OUT_CMDS}"
done

if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo "[DRY RUN] Commands written to ${OUT_CMDS}"
  echo "Top AMI candidates (ImageId,OwnerId,CreationDate,Public,Name):"
  head -n 20 "${OUT_CSV}" | tail -n +2 || true
  exit 0
fi

# ------------------------
# LIVE execution
# ------------------------
echo "[LIVE] Deregistering AMIs..."
deleted=0
while IFS= read -r line; do
  [[ -z "${line}" ]] && continue
  echo "${line}"
  # shellcheck disable=SC2086
  ${line}
  deleted=$((deleted+1))
done < "${OUT_CMDS}"

if [[ -s "${OUT_CMDS}" ]]; then
  echo "First 20 deregistration commands:"
  grep '^aws ec2 deregister-image' "${OUT_CMDS}" | head -n 20 || true
fi

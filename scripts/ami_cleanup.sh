# scripts/ami_cleanup.sh
#!/bin/bash
# Don't forget to set your default profile
# export AWS_DEFAULT_PROFILE=nomis-development

# STRICT, but we’ll locally relax around tools like join/comm/aws when “no matches” is normal.
set -euo pipefail

# ---------- Defaults ----------
aws_cmd_file=""
months=""
application=""
environment=""
include_backup=0
include_images_in_code=0
include_images_on_ec2=1
dryrun=0
valid_actions=("used" "account" "code" "delete")
profile=""
aws_error_log="aws_error.log"

# ---------- Helpers ----------
usage() {
  echo -e "Usage:\n $0 [<opts>] $(IFS='|'; echo "${valid_actions[*]}")"
  echo "Where <opts>:"
  echo "  -a <application>       e.g. nomis or core-shared-services"
  echo "  -b                     Include AwsBackup images"
  echo "  -c                     Include images referenced in code"
  echo "  -d                     Dry-run for delete"
  echo "  -e <environment>       required if -a core-shared-services"
  echo "  -m <months>            Exclude images newer than <months>"
  echo "  -s <file>              Output deregister commands to file"
  echo "Actions: used | account | code | delete"
}

# Deterministic sort and normalization for set-ops
clean_sort() { sed -e 's/\r$//' -e '/^$/d' | LC_ALL=C sort -u; }

# Convert AWS TEXT (tab-delimited) to CSV while preserving AMI names with spaces
aws_text_to_csv() {
  awk -F'\t' 'BEGIN{OFS=","} {
    name=$5;
    if (NF>5) { for(i=6;i<=NF;i++){ name=name " " $i } }
    gsub(/\r/,"",name);
    print $1,$2,$3,$4,name
  }'
}

# ---------- Date handling ----------
set_date_cmd() {
  if [[ "$(uname)" == "Darwin" ]]; then
    if command -v gdate >/dev/null 2>&1; then
      date_cmd="gdate"
    else
      echo "Please install coreutils: brew install coreutils" >&2
      exit 1
    fi
  else
    date_cmd="date"
  fi
  now="$($date_cmd +%s)"
}

date_minus_month() { local month="$1"; shift; "$date_cmd" -d "-${month} month" "$@"; }

# Build a loose creation-date filter for <months>. Empty/0 -> no filter.
get_date_filter() {
  local m="${1:-}"
  [[ -z "$m" || "$m" == "0" ]] && { echo ""; return 0; }

  local date_filter="" i
  local m1 m2 m3
  m1="$(date_minus_month "$m" "+%m")"
  m2="${m1#0}"
  m3=$((m + m2))

  if (( m2 < 12 )); then
    for ((i=m; i<m3; i++)); do
      date_filter+="$(date_minus_month "$i" "+%Y-%m-*"),"
    done
  else
    date_filter+="$(date_minus_month "$m2" "+%Y-*"),"
  fi
  date_filter+="$(date_minus_month $((m3+1)) "+%Y-*"),"
  date_filter+="$(date_minus_month $((m3+13)) "+%Y-*"),"
  date_filter+="$(date_minus_month $((m3+25)) "+%Y-*")"
  echo "$date_filter"
}

# ---------- AWS collectors ----------
get_account_images_csv() {
  local months_arg="${1:-}"
  local include_backup_arg="${2:-0}"

  local filters="" df
  df="$(get_date_filter "$months_arg" || true)"
  if [[ -n "$df" ]]; then
    filters="--filters Name=creation-date,Values=$df"
  fi

  # Avoid pipefail on empty
  local out=""
  out="$(aws ec2 describe-images $filters $profile \
           --owners self \
           --query 'Images[].[ImageId, OwnerId, CreationDate, Public, Name]' \
           --output text 2> "$aws_error_log" || true)"
  if [[ -n "$out" ]]; then
    out="$(printf "%s" "$out" | aws_text_to_csv)"
  fi

  if [[ "$include_backup_arg" -eq 0 ]]; then
    printf "%s\n" "$out" | grep -v 'AwsBackup' || true
  else
    printf "%s\n" "$out"
  fi
}

get_usage_report_csv() {
  # Only used for core-shared-services-production path
  local list
  list="$(get_account_images_csv "$months" "$include_backup" || true)"
  [[ -z "$list" ]] && return 0

  while IFS= read -r ami; do
    [[ -z "$ami" ]] && continue
    IFS=',' read -r image_id owner_id creation_date public name <<< "$ami"
    [[ -z "${image_id:-}" ]] && continue

    local report_id="" report_usage=""
    report_id="$(aws ec2 create-image-usage-report $profile \
                --image-id "$image_id" \
                --resource-types ResourceType=ec2:Instance 'ResourceType=ec2:LaunchTemplate,ResourceTypeOptions=[{OptionName=version-depth,OptionValues=100}]' \
                --output text 2>> "$aws_error_log" || true)"
    [[ -z "$report_id" ]] && continue
    report_usage="$(aws ec2 describe-image-usage-report-entries $profile \
                  --report-id "$report_id" \
                  --output text 2>> "$aws_error_log" || true)"
    [[ -n "$report_usage" ]] && echo "$ami"
  done <<< "$list"
}

get_ec2_instance_images_csv() {
  if [[ "$application" == "core-shared-services-production" ]]; then
    get_usage_report_csv || true
  else
    local inst_out=""
    inst_out="$(aws ec2 describe-instances $profile \
               --query "Reservations[*].Instances[*].ImageId" \
               --output text 2> "$aws_error_log" || true)"
    [[ -z "$inst_out" ]] && return 0

    # unique ImageIds
    mapfile -t ids < <(printf "%s" "$inst_out" | tr '\t' '\n' | sed '/^$/d' | LC_ALL=C sort -u)
    (( ${#ids[@]} == 0 )) && return 0

    local img_out=""
    img_out="$(aws ec2 describe-images $profile \
             --image-ids "${ids[@]}" \
             --query 'Images[].[ImageId, OwnerId, CreationDate, Public, Name]' \
             --output text 2> "$aws_error_log" || true)"
    [[ -z "$img_out" ]] && return 0
    printf "%s" "$img_out" | aws_text_to_csv
  fi
}

get_code_image_names() {
  local app="${1:-}"
  local envdir tf_files
  if [[ "$app" == "core-shared-services-production" ]]; then
    envdir="$(dirname "$0")/../../modernisation-platform/terraform/environments/core-shared-services"
  else
    envdir="$(dirname "$0")/../../modernisation-platform-environments/terraform/environments/$app"
  fi
  [[ ! -d "$envdir" ]] && { echo "Cannot find $envdir" >&2; exit 1; }

  if [[ -n "$app" ]]; then
    tf_files="${envdir}/*.tf"
  else
    tf_files="${envdir}/*/*.tf"
  fi
  # shellcheck disable=SC2086
  grep -Eo 'ami_name[[:space:]]*=[[:space:]]*"[^"]*"' $tf_files 2>/dev/null \
    | cut -d\" -f2 \
    | LC_ALL=C sort -u \
    | grep -vF '*' \
    | LC_ALL=C sort -u || true
}

# ---------- Set operations (safe for empty inputs) ----------
get_code_csv() {
  local ami code
  ami="$(get_account_images_csv 0 | LC_ALL=C sort -t, -k5,5 || true)"
  code="$(get_code_image_names "$1" | LC_ALL=C sort || true)"
  # join exit 1 on no matches: treat as empty
  join -o 1.1,1.2,1.3,1.4,1.5 -t, -1 5 <(echo "${ami}") <(echo "${code}") 2>/dev/null || true
}

get_in_use_images_csv() {
  local include_ec2="$1" include_code="$2" app="$3"
  local csv_ec2="" csv_code=""
  if [[ "$include_ec2" -eq 1 ]]; then
    csv_ec2="$(get_ec2_instance_images_csv | clean_sort || true)"
  fi
  if [[ "$include_code" -eq 1 ]]; then
    csv_code="$(get_code_csv "$app" | clean_sort || true)"
  fi
  printf "%s\n%s\n" "${csv_ec2}" "${csv_code}" | clean_sort
}

get_images_to_delete_csv() {
  local include_ec2="$1" include_code="$2" app="$3" months_arg="${4:-}" include_backup_arg="${5:-0}"

  local account in_use
  account="$(get_account_images_csv "$months_arg" "$include_backup_arg" | clean_sort || true)"
  in_use="$(get_in_use_images_csv "$include_ec2" "$include_code" "$app" | clean_sort || true)"
  # comm exit 1 on empty/no overlap: treat as empty
  comm -23 <(echo "${account}") <(echo "${in_use}") 2>/dev/null || true
}

# ---------- Delete / Emit commands ----------
delete_images() {
  local dryrun_flag="$1" aws_cmd_file_arg="${2:-}" csv="${3:-}"

  [[ -z "$aws_cmd_file_arg" ]] && aws_cmd_file_arg="ami_delete_commands.sh"

  # Ensure the file exists even if we later find 0 candidates
  {
    echo "#!/bin/bash"
    echo "# Generated AWS deregistration commands"
  } > "$aws_cmd_file_arg"
  chmod +x "$aws_cmd_file_arg"

  local count=0
  if [[ -n "$csv" ]]; then
    while IFS=',' read -r image_id owner_id creation_date public name; do
      [[ -z "${image_id:-}" ]] && continue
      echo "aws ec2 deregister-image --image-id $image_id $profile" >> "$aws_cmd_file_arg"
      ((count++))
    done <<< "$csv"
  fi

  {
    echo ""
    echo "# Summary: $count AMI(s) slated for deregistration"
  } >> "$aws_cmd_file_arg"

  echo "Found $count AMI(s) to deregister."
  if [[ "$dryrun_flag" -eq 1 ]]; then
    echo "[DRY RUN] Commands written to $aws_cmd_file_arg"
  else
    if (( count > 0 )); then
      echo "[LIVE] Deregistering AMIs..."
      bash "$aws_cmd_file_arg"
    else
      echo "[LIVE] No AMIs to deregister."
    fi
  fi
}

# ---------- Input parsing ----------
parse_inputs() {
  while getopts "a:bcde:xm:s:" opt; do
    case $opt in
      a) application="${OPTARG}" ;;
      b) include_backup=1 ;;
      c) include_images_in_code=1 ;;
      d) dryrun=1 ;;
      e) environment="${OPTARG}" ;;
      x) include_images_on_ec2=0 ;;
      m) months="${OPTARG}" ;;
      s) aws_cmd_file="${OPTARG}" ;;
      :) echo "Error: option -$OPTARG requires an argument" >&2; usage >&2; exit 1 ;;
      ?) echo "Invalid option: -${OPTARG}" >&2; echo; usage >&2; exit 1 ;;
    esac
  done
  shift $((OPTIND-1))

  if (( $# != 1 )); then
    echo "Error: exactly one action expected (used|account|code|delete)" >&2
    usage >&2
    exit 1
  fi
  action="$1"

  if [[ "$application" == "core-shared-services" ]]; then
    if [[ -n "$environment" ]]; then
      profile="--profile $application-$environment"
    else
      echo "For core-shared-services you must specify -e <environment>" >&2
      exit 1
    fi
  fi
}

# ---------- Error handling ----------
check_aws_error() { :; }  # Intentionally no-op; we tolerate empty/no-match states.

cleanup() { rm -f "$aws_error_log" || true; }

# ---------- Main ----------
main() {
  parse_inputs "$@"
  set_date_cmd

  case "$action" in
    used)
      get_in_use_images_csv "$include_images_on_ec2" "$include_images_in_code" "$application" || true
      ;;
    account)
      get_account_images_csv "$months" "$include_backup" | clean_sort || true
      ;;
    code)
      get_code_image_names "$application" || true
      ;;
    delete)
      # Always prepare output file so the artifact step finds it even on errors/empties
      [[ -n "$aws_cmd_file" ]] || aws_cmd_file="ami_delete_commands.sh"
      : > "$aws_cmd_file"; echo -e "#!/bin/bash\n# Generated AWS deregistration commands" > "$aws_cmd_file"; chmod +x "$aws_cmd_file"

      csv="$(get_images_to_delete_csv "$include_images_on_ec2" "$include_images_in_code" "$application" "$months" "$include_backup" || true)"
      # Write candidates file (0 bytes if none)
      if [[ -n "${csv}" ]]; then
        printf "%s\n" "${csv}" > ami_candidates.csv
      else
        : > ami_candidates.csv
      fi
      delete_images "$dryrun" "$aws_cmd_file" "$csv"
      ;;
    *)
      usage >&2; exit 1 ;;
  esac

  cleanup
}

main "$@"

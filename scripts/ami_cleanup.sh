#!/bin/bash
# scripts/ami_cleanup.sh
# Usage example:
#   scripts/ami_cleanup.sh -a nomis -m 3 -c -d -s ami_commands.sh delete

# Be strict, but we'll locally guard commands that can legitimately "fail" (no matches/empty).
set -euo pipefail

# ---------------------------
# Defaults / globals
# ---------------------------
application=""
environment=""
months=""
include_backup=0               # 0=exclude AwsBackup AMIs, 1=include
include_images_in_code=0       # -c flag
include_images_on_ec2=1        # can be disabled with -x (testing)
dryrun=0                       # -d flag
aws_cmd_file=""                # -s file
profile=""                     # only used for core-shared-services with -e
aws_error_log="aws_error.log"

# tmp files (deleted on exit)
tmpdir="$(mktemp -d)"
account_csv="$tmpdir/account.csv"         # ImageId,OwnerId,CreationDate,Public,Name
ec2_csv="$tmpdir/ec2.csv"                 # ImageId,OwnerId,CreationDate,Public,Name
code_names="$tmpdir/code_names.txt"       # plain AMI names from code
inuse_ids="$tmpdir/inuse_ids.set"         # ImageId set (from EC2)
inuse_names="$tmpdir/inuse_names.set"     # Name set (from code intersect account)
candidates_csv="$tmpdir/candidates.csv"   # final delete candidates

cleanup() {
  rm -rf "$tmpdir" || true
  rm -f "$aws_error_log" || true
}
trap cleanup EXIT

usage() {
  cat <<EOF
Usage: $0 [options] <action>

Options:
  -a <application>      Application (e.g., nomis or core-shared-services)
  -e <environment>      Environment (required if -a core-shared-services)
  -m <months>           Only consider AMIs older than this many months; empty/0 = no filter
  -b                    Include AwsBackup images (default excludes them)
  -c                    Include images referenced in code (protect by name)
  -d                    Dry-run (don't deregister)
  -s <file>             Output AWS deregister commands to this file (default: ami_delete_commands.sh)
  -x                    Exclude images in use on EC2 (testing switch; default includes EC2 use)

Actions:
  used      Print images in use (EC2 and/or code if -c)
  account   Print all account AMIs (after filters)
  code      Print AMI names referenced in code
  delete    Write deregister commands for unused AMIs

Examples:
  $0 -a nomis -m 3 -c -d -s ami_commands.sh delete
EOF
}

# Normalize lines and sort deterministically
normalize_sort() { sed -e 's/\r$//' -e '/^$/d' | LC_ALL=C sort -u; }

# Convert AWS TEXT (tab-delimited) to CSV (ImageId,OwnerId,CreationDate,Public,Name)
aws_text_to_csv() {
  awk -F'\t' 'BEGIN{OFS=","} {
    name=$5;
    if (NF>5) { for(i=6;i<=NF;i++){ name=name " " $i } }
    gsub(/\r/,"",name);
    print $1,$2,$3,$4,name
  }'
}

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
}

date_minus_month() { local m="${1}"; shift; "$date_cmd" -d "-${m} month" "$@"; }

# Build creation-date filter for --filters (empty string means no filter)
build_creation_date_filter() {
  local m="${1:-}"
  [[ -z "$m" || "$m" == "0" ]] && { echo ""; return 0; }

  local df="" i m1 m2 m3
  m1="$(date_minus_month "$m" "+%m")"
  m2="${m1#0}"
  m3=$((m + m2))

  if (( m2 < 12 )); then
    for (( i=m; i<m3; i++ )); do
      df+=$(date_minus_month "$i" "+%Y-%m-*"),
    done
  else
    df+=$(date_minus_month "$m2" "+%Y-*"),
  fi
  df+=$(date_minus_month $((m3+1)) "+%Y-*"),
  df+=$(date_minus_month $((m3+13)) "+%Y-*"),
  df+=$(date_minus_month $((m3+25)) "+%Y-*")
  echo "$df"
}

# ---------------------------
# Collectors
# ---------------------------
collect_account_images() {
  local filters="" df
  df="$(build_creation_date_filter "${months}")"
  if [[ -n "$df" ]]; then
    filters="--filters Name=creation-date,Values=$df"
  fi

  local out=""
  out="$(aws ec2 describe-images $filters $profile \
          --owners self \
          --query 'Images[].[ImageId, OwnerId, CreationDate, Public, Name]' \
          --output text 2>>"$aws_error_log" || true)"

  if [[ -n "$out" ]]; then
    printf "%s" "$out" | aws_text_to_csv | {
      if [[ "$include_backup" -eq 0 ]]; then
        grep -v 'AwsBackup' || true
      else
        cat
      fi
    } | normalize_sort > "$account_csv"
  else
    : > "$account_csv"
  fi
}

# Special path uses image usage report (as per your earlier variant)
collect_inuse_ids_via_usage_report() {
  # Only for core-shared-services-production
  : > "$inuse_ids"
  while IFS=',' read -r image_id _rest; do
    [[ -z "$image_id" ]] && continue
    local rid usage
    rid="$(aws ec2 create-image-usage-report $profile \
            --image-id "$image_id" \
            --resource-types ResourceType=ec2:Instance 'ResourceType=ec2:LaunchTemplate,ResourceTypeOptions=[{OptionName=version-depth,OptionValues=100}]' \
            --output text 2>>"$aws_error_log" || true)"
    [[ -z "$rid" ]] && continue
    usage="$(aws ec2 describe-image-usage-report-entries $profile \
              --report-id "$rid" \
              --output text 2>>"$aws_error_log" || true)"
    if [[ -n "$usage" ]]; then
      echo "$image_id"
    fi
  done < "$account_csv" | normalize_sort > "$inuse_ids"
}

collect_inuse_ids_via_instances() {
  : > "$inuse_ids"
  local ids_text=""
  ids_text="$(aws ec2 describe-instances $profile \
              --query "Reservations[*].Instances[*].ImageId" \
              --output text 2>>"$aws_error_log" || true)"
  if [[ -n "$ids_text" ]]; then
    printf "%s\n" "$ids_text" | tr '\t' '\n' | normalize_sort > "$inuse_ids"
  fi
}

collect_inuse_from_ec2() {
  [[ "$include_images_on_ec2" -eq 1 ]] || { : > "$inuse_ids"; return 0; }

  if [[ "$application" == "core-shared-services" && "$environment" == "production" ]]; then
    collect_inuse_ids_via_usage_report
  else
    collect_inuse_ids_via_instances
  fi

  # If we have IDs, enrich to CSV rows (so we can see Image Name if needed)
  if [[ -s "$inuse_ids" ]]; then
    local img_out=""
    mapfile -t ids < "$inuse_ids"
    img_out="$(aws ec2 describe-images $profile \
              --image-ids "${ids[@]}" \
              --query 'Images[].[ImageId, OwnerId, CreationDate, Public, Name]' \
              --output text 2>>"$aws_error_log" || true)"
    if [[ -n "$img_out" ]]; then
      printf "%s" "$img_out" | aws_text_to_csv | normalize_sort > "$ec2_csv"
    else
      : > "$ec2_csv"
    fi
  else
    : > "$ec2_csv"
  fi
}

collect_code_names() {
  : > "$code_names"
  local envdir tf_files
  if [[ "$application" == "core-shared-services" && "$environment" == "production" ]]; then
    envdir="$(dirname "$0")/../../modernisation-platform/terraform/environments/core-shared-services"
  else
    envdir="$(dirname "$0")/../../modernisation-platform-environments/terraform/environments/$application"
  fi
  if [[ -d "$envdir" ]]; then
    if [[ -n "$application" ]]; then
      tf_files="$envdir/*.tf"
    else
      tf_files="$envdir/*/*.tf"
    fi
    # shellcheck disable=SC2086
    grep -Eo 'ami_name[[:space:]]*=[[:space:]]*"[^"]*"' $tf_files 2>/dev/null \
      | cut -d\" -f2 \
      | grep -vF '*' \
      | normalize_sort > "$code_names" || true
  fi
}

# ---------------------------
# Set operations (no comm/join)
# ---------------------------
# Build in-use names set = intersection of code names with account names (only names present in account)
build_inuse_names_from_code() {
  : > "$inuse_names"
  [[ "$include_images_in_code" -eq 1 ]] || return 0
  [[ -s "$code_names" && -s "$account_csv" ]] || return 0

  awk -F',' '
    BEGIN {OFS=","}
    FNR==NR { acc_names[$5]=1; next }         # pass 1: account_csv (name at $5)
    ($0 in acc_names) { print $0 }            # pass 2: code_names; only keep those present in account
  ' "$account_csv" "$code_names" | normalize_sort > "$inuse_names"
}

# Compute candidates: account minus (in-use IDs or in-use names)
compute_candidates() {
  : > "$candidates_csv"
  awk -F',' -v ec2_ids="$inuse_ids" -v code_names="$inuse_names" '
    BEGIN {
      # load EC2 in-use image IDs
      while ((getline line < ec2_ids) > 0) { gsub(/\r/,"",line); if (line!="") id[line]=1 }
      close(ec2_ids)
      # load code in-use names
      while ((getline nm < code_names) > 0) { gsub(/\r/,"",nm); if (nm!="") name[nm]=1 }
      close(code_names)
    }
    {
      img=$1; nm=$5
      if (img in id) next
      if (nm in name) next
      print $0
    }
  ' "$account_csv" | normalize_sort > "$candidates_csv"
}

# ---------------------------
# Emit commands / Outputs
# ---------------------------
emit_commands() {
  local outfile="$1"
  [[ -n "$outfile" ]] || outfile="ami_delete_commands.sh"
  {
    echo "#!/bin/bash"
    echo "# Generated AWS deregistration commands"
  } > "$outfile"
  chmod +x "$outfile"

  local count=0
  if [[ -s "$candidates_csv" ]]; then
    while IFS=',' read -r image_id _rest; do
      [[ -z "$image_id" ]] && continue
      echo "aws ec2 deregister-image --image-id $image_id $profile" >> "$outfile"
      ((count++))
    done < <(cut -d',' -f1 "$candidates_csv")
  fi

  {
    echo ""
    echo "# Summary: ${count} AMI(s) slated for deregistration"
  } >> "$outfile"

  echo "$count"
}

# ---------------------------
# Actions
# ---------------------------
action=""
parse_inputs() {
  while getopts "a:bcde:xm:s:" opt; do
    case "$opt" in
      a) application="${OPTARG}" ;;
      b) include_backup=1 ;;
      c) include_images_in_code=1 ;;
      d) dryrun=1 ;;
      e) environment="${OPTARG}" ;;
      x) include_images_on_ec2=0 ;;
      m) months="${OPTARG}" ;;
      s) aws_cmd_file="${OPTARG}" ;;
      :) echo "Option -$OPTARG requires an argument" >&2; usage; exit 1 ;;
      ?) echo "Invalid option: -$OPTARG" >&2; usage; exit 1 ;;
    esac
  done
  shift $((OPTIND-1))
  if (( $# != 1 )); then
    echo "Error: exactly one action expected (used|account|code|delete)" >&2
    usage
    exit 1
  fi
  action="$1"

  # Only set AWS profile for core-shared-services; GH runner already assumes role via OIDC.
  if [[ "$application" == "core-shared-services" && -z "${environment}" ]]; then
    echo "For core-shared-services you must specify -e <environment>" >&2
    exit 1
  fi
  if [[ "$application" == "core-shared-services" ]]; then
    profile="--profile ${application}-${environment}"
  else
    profile="" # use environment credentials
  fi
}

main() {
  parse_inputs "$@"
  set_date_cmd

  # Collect base data
  collect_account_images

  case "$action" in
    account)
      cat "$account_csv"
      return 0
      ;;
    code)
      collect_code_names
      cat "$code_names"
      return 0
      ;;
    used)
      : > "$inuse_ids"; : > "$inuse_names"
      collect_inuse_from_ec2
      collect_code_names
      build_inuse_names_from_code
      # Show combined in-use as CSV (by ID records + name-only hints)
      # First EC2-backed rows (CSV)
      if [[ -s "$ec2_csv" ]]; then cat "$ec2_csv"; fi
      # Then name-only rows (emit as pseudo CSV with empty id fields to avoid confusion)
      if [[ -s "$inuse_names" ]]; then
        awk '{print ",,,," $0}' "$inuse_names"
      fi
      return 0
      ;;
    delete)
      collect_inuse_from_ec2
      collect_code_names
      build_inuse_names_from_code
      compute_candidates

      # Ensure outfile exists for artifact upload even if 0 candidates
      [[ -n "$aws_cmd_file" ]] || aws_cmd_file="ami_commands.sh"
      count="$(emit_commands "$aws_cmd_file")"

      if [[ "$dryrun" -eq 1 ]]; then
        echo "[DRY RUN] Commands written to $aws_cmd_file"
      else
        if (( count > 0 )); then
          echo "[LIVE] Deregistering AMIs..."
          bash "$aws_cmd_file"
        else
          echo "[LIVE] No AMIs to deregister."
        fi
      fi
      # Also upload candidates list for visibility (AMIId,...)
      cp "$candidates_csv" ./ami_candidates.csv || : 
      return 0
      ;;
    *)
      usage; exit 1 ;;
  esac
}

main "$@"
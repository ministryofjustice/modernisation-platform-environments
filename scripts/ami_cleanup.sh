# scripts/ami_cleanup.sh
#!/bin/bash
# Usage examples:
#   scripts/ami_cleanup.sh -a example -m 3 -c -d -s ami_commands.sh delete
#   scripts/ami_cleanup.sh -a example -c --test-mode --age-minutes 10 -d delete
#   scripts/ami_cleanup.sh -a example -c --delete-snapshots delete

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

# Test-mode overrides (minutes-based age)
test_mode=0
age_minutes=""

# Snapshot deletion toggle
delete_snapshots=0

# tmp files (deleted on exit)
tmpdir="$(mktemp -d)"
account_csv="$tmpdir/account.csv"         # ImageId,OwnerId,CreationDate,Public,Name
ec2_csv="$tmpdir/ec2.csv"                 # ImageId,OwnerId,CreationDate,Public,Name
code_names="$tmpdir/code_names.txt"       # plain AMI names from code
inuse_ids="$tmpdir/inuse_ids.set"         # ImageId set (from EC2)
inuse_names="$tmpdir/inuse_names.set"     # Name set (from code intersect account)
candidates_csv="$tmpdir/candidates.csv"   # final delete candidates
cand_ids="$tmpdir/candidate_ids.set"      # candidate AMI ids (set)
snap_candidates_csv="$tmpdir/snap_candidates.csv" # AMI,SNAPSHOT pairs (pre-check)
snap_final_csv="$tmpdir/snap_final.csv"          # snapshots approved for delete

# output files in CWD for artifacts
out_ami_candidates="./ami_candidates.csv"
out_ami_cmds="./ami_commands.sh"
out_snap_candidates="./ami_snapshots.csv"
out_snap_cmds="./snapshot_commands.sh"

cleanup() {
  rm -rf "$tmpdir" || true
  rm -f "$aws_error_log" || true
}
trap cleanup EXIT

usage() {
  cat <<EOF
Usage: $0 [options] <action>
Options:
  -a <application>      Application (e.g., example or core-shared-services)
  -e <environment>      Environment (required if -a core-shared-services)
  -m <months>           Only consider AMIs older than this many months; empty/0 = no month filter
  -b                    Include AwsBackup images (default excludes them)
  -c                    Include images referenced in code (protect by name)
  -d                    Dry-run (don't deregister / delete)
  -s <file>             Output AWS deregister commands to this file (default: ami_delete_commands.sh)
  -x                    Exclude images in use on EC2 (testing switch; default includes EC2 use)
  --test-mode           Enable test mode (required when using --age-minutes)
  --age-minutes <N>     In test mode, consider AMIs older than N minutes (overrides month filter)
  --delete-snapshots    After deregistering AMIs, also delete orphaned snapshots they used
Actions:
  used      Print images in use (EC2 and/or code if -c)
  account   Print all account AMIs (after filters)
  code      Print AMI names referenced in code
  delete    Write deregister commands for unused AMIs (or execute if not dry-run)
Examples:
  $0 -a example -m 3 -c -d -s ami_commands.sh delete
  $0 -a example -c --test-mode --age-minutes 10 -d delete
  $0 -a example -c --delete-snapshots delete
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
  if (( test_mode == 1 )) && [[ -n "${age_minutes:-}" ]]; then
    filters=""
  else
    df="$(build_creation_date_filter "${months}")"
    if [[ -n "$df" ]]; then
      filters="--filters Name=creation-date,Values=$df"
    fi
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

collect_inuse_ids_via_usage_report() {
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
# Set operations & test-mode time filter
# ---------------------------
within_minutes_cutoff() {
  local creation_iso="$1"
  local cutoff_secs="$2"
  local created_epoch
  created_epoch="$("$date_cmd" -d "${creation_iso}" +%s 2>/dev/null || echo 0)"
  [[ "$created_epoch" -le "$cutoff_secs" ]]
}

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

compute_candidates() {
  : > "$candidates_csv"
  local cutoff_secs=0
  if (( test_mode == 1 )) && [[ -n "${age_minutes:-}" ]] && [[ "$age_minutes" =~ ^[0-9]+$ ]] && (( age_minutes > 0 )); then
    local now_secs; now_secs="$("$date_cmd" +%s)"
    cutoff_secs=$(( now_secs - age_minutes*60 ))
  fi

  awk -F',' -v ec2_ids="$inuse_ids" -v code_names="$inuse_names" -v cutoff_secs="$cutoff_secs" -v test_mode="$test_mode" -v datecmd="$date_cmd" '
    BEGIN {
      while ((getline line < ec2_ids) > 0) { gsub(/\r/,"",line); if (line!="") id[line]=1 }
      close(ec2_ids)
      while ((getline nm < code_names) > 0) { gsub(/\r/,"",nm); if (nm!="") name[nm]=1 }
      close(code_names)
    }
    {
      img=$1; created=$3; nm=$5
      if (img in id) next
      if (nm in name) next
      print $0
    }
  ' "$account_csv" | normalize_sort > "$candidates_csv"

  if (( test_mode == 1 )) && [[ "$cutoff_secs" -gt 0 ]]; then
    awk -F',' -v cutoff_secs="$cutoff_secs" -v dc="$date_cmd" '
      function to_epoch(iso,   cmd) {
        cmd = sprintf("%s -d \"%s\" +%%s 2>/dev/null", dc, iso)
        cmd | getline out
        close(cmd)
        return out+0
      }
      {
        created=$3
        if (to_epoch(created) <= cutoff_secs) print $0
      }
    ' "$candidates_csv" | normalize_sort > "${candidates_csv}.tmp"
    mv "${candidates_csv}.tmp" "$candidates_csv"
  fi

  # Build a set of candidate AMI IDs for quick lookups in snapshot checks
  cut -d',' -f1 "$candidates_csv" | normalize_sort > "$cand_ids"
}

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
# Snapshot helpers (Optional)
# ---------------------------

# Fill snap_candidates_csv with AMI,SNAPSHOT pairs for candidate AMIs
collect_snapshot_candidates() {
  : > "$snap_candidates_csv"
  [[ -s "$cand_ids" ]] || return 0
  while read -r ami; do
    [[ -z "$ami" ]] && continue
    snaps="$(aws ec2 describe-images $profile \
      --image-ids "$ami" \
      --query 'Images[0].BlockDeviceMappings[].Ebs.SnapshotId' \
      --output text 2>>"$aws_error_log" || true)"
    if [[ -n "${snaps:-}" ]]; then
      for s in $snaps; do
        [[ "$s" =~ ^snap- ]] || continue
        echo "${ami},${s}" >> "$snap_candidates_csv"
      done
    fi
  done < "$cand_ids"
  if [[ -s "$snap_candidates_csv" ]]; then
    LC_ALL=C sort -u "$snap_candidates_csv" -o "$snap_candidates_csv"
  fi
}

# Return 0 if snapshot has a retention/backup indicator
snapshot_is_retained() {
  local snap_id="$1"
  local tags desc name
  read -r tags desc name < <(aws ec2 describe-snapshots $profile \
    --snapshot-ids "$snap_id" \
    --query '[Snapshots[0].Tags, Snapshots[0].Description, Snapshots[0].Tags[?Key==`Name`]|[0].Value]' \
    --output text 2>>"$aws_error_log" || echo "")
  # Tag-based retention
  if echo "$tags" | grep -Eiq '(^|[[:space:]])(Retain|Backup)[[:space:]]*=[[:space:]]*(true|yes|1)'; then
    return 0
  fi
  # Name/desc indicates AwsBackup
  if echo "$desc $name" | grep -qi 'AwsBackup'; then
    return 0
  fi
  return 1
}

# Return 0 if snapshot is referenced by any other AMI not in the candidate set
snapshot_referenced_elsewhere() {
  local snap_id="$1"
  local img_ids
  img_ids="$(aws ec2 describe-images $profile \
    --owners self \
    --filters Name=block-device-mapping.snapshot-id,Values="$snap_id" \
    --query 'Images[].ImageId' \
    --output text 2>>"$aws_error_log" || true)"
  [[ -z "$img_ids" ]] && return 1
  # If any image id is NOT in cand_ids, then it's referenced elsewhere → return 0 (true)
  while read -r img; do
    [[ -z "$img" ]] && continue
    if ! grep -qx "$img" "$cand_ids" 2>/dev/null; then
      return 0
    fi
  done <<< "$img_ids"
  return 1
}

# Build snapshot delete commands into out_snap_cmds and list into out_snap_candidates
emit_snapshot_commands() {
  : > "$out_snap_cmds"
  chmod +x "$out_snap_cmds"
  : > "$out_snap_candidates"

  local count=0
  if [[ -s "$snap_candidates_csv" ]]; then
    while IFS=',' read -r ami snap; do
      [[ -z "$snap" ]] && continue
      # Skip retained
      if snapshot_is_retained "$snap"; then
        continue
      fi
      # Skip if referenced by other AMIs not being deleted
      if snapshot_referenced_elsewhere "$snap"; then
        continue
      fi
      echo "${ami},${snap}" >> "$out_snap_candidates"
      echo "aws ec2 delete-snapshot --snapshot-id ${snap} $profile" >> "$out_snap_cmds"
      ((count++))
    done < "$snap_candidates_csv"
  fi

  {
    echo ""
    echo "# Summary: ${count} snapshot(s) slated for deletion"
  } >> "$out_snap_cmds"

  echo "$count"
}

# ---------------------------
# Argument parsing
# ---------------------------
action=""
parse_inputs() {
  long_args=()
  while (( "$#" )); do
    case "$1" in
      --test-mode) test_mode=1; shift ;;
      --age-minutes) age_minutes="${2:-}"; shift 2 ;;
      --age-minutes=*) age_minutes="${1#*=}"; shift ;;
      --delete-snapshots) delete_snapshots=1; shift ;;
      *) long_args+=("$1"); shift ;;
    esac
  done
  set -- "${long_args[@]}"

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

  if [[ -n "${age_minutes:-}" && "$test_mode" -ne 1 ]]; then
    echo "--age-minutes requires --test-mode" >&2
    exit 1
  fi

  if [[ "$application" == "core-shared-services" && -z "${environment}" ]]; then
    echo "For core-shared-services you must specify -e <environment>" >&2
    exit 1
  fi
  if [[ "$application" == "core-shared-services" ]]; then
    profile="--profile ${application}-${environment}"
  else
    profile=""
  fi
}

# ---------------------------
# Main
# ---------------------------
main() {
  parse_inputs "$@"
  set_date_cmd

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
      if [[ -s "$ec2_csv" ]]; then cat "$ec2_csv"; fi
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

      [[ -n "$aws_cmd_file" ]] || aws_cmd_file="$out_ami_cmds"
      count="$(emit_commands "$aws_cmd_file")"
      cp "$candidates_csv" "$out_ami_candidates" || :

      # If snapshot deletion requested, pre-compute snapshot commands now (before AMI deregister).
      snap_count=0
      if (( delete_snapshots == 1 )); then
        collect_snapshot_candidates
        snap_count="$(emit_snapshot_commands)"
      fi

      if [[ "$dryrun" -eq 1 ]]; then
        echo "[DRY RUN] Commands written to $aws_cmd_file"
        if (( delete_snapshots == 1 )); then
          echo "[DRY RUN] Snapshot delete commands written to $out_snap_cmds"
        fi
      else
        if (( count > 0 )); then
          echo "[LIVE] Deregistering AMIs..."
          bash "$aws_cmd_file"
        else
          echo "[LIVE] No AMIs to deregister."
        fi
        if (( delete_snapshots == 1 )); then
          if [[ -s "$out_snap_cmds" ]]; then
            echo "[LIVE] Deleting orphaned snapshots used by deregistered AMIs..."
            bash "$out_snap_cmds"
          else
            echo "[LIVE] No snapshots matched the deletion criteria."
          fi
        fi
      fi
      return 0
      ;;
    *)
      usage; exit 1 ;;
  esac
}

main "$@"

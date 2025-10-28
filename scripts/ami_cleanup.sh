# scripts/ami_cleanup.sh
#!/bin/bash
# Don't forget to set your default profile
# export AWS_DEFAULT_PROFILE=nomis-development

set -eo pipefail

# defaults
aws_cmd_file=
months=
application=
include_backup=0
include_images_in_code=0
include_images_on_ec2=1
dryrun=0
valid_actions=("used" "account" "code" "delete")
profile=''
aws_error_log='aws_error.log'

usage() {
  echo -e "Usage:\n $0 [<opts>] $(IFS='|'; echo "${valid_actions[*]}")
Where <opts>:
  -a <application>       Specify which application for images e.g. nomis or core-shared-services
  -b                     Optionally include AwsBackup images
  -c                     Also include images referenced in code
  -d                     Dryrun for delete command
  -e <environment>       Specify which environment for images e.g. production (only needed for core-shared-services)
  -m <months>            Exclude images younger than this number of months
  -s <file>              Output AWS shell commands to file
And:
  used                   List all images in use (and -c flag to include code)
  account                List all images in the current account
  code                   List all image names referenced in code
  delete                 Delete unused images
"
}

main() {
  parse_inputs "$@"
  set_date_cmd
  case $action in
    used)
      get_in_use_images_csv "$include_images_on_ec2" "$include_images_in_code" "$application" ;;
    account)
      get_account_images_csv "$months" "$include_backup" | clean_sort ;;
    code)
      get_code_image_names "$application" ;;
    delete)
      csv=$(get_images_to_delete_csv "$include_images_on_ec2" "$include_images_in_code" "$application" "$months" "$include_backup")
      printf "%s\n" "$csv" > ami_candidates.csv
      delete_images "$dryrun" "$aws_cmd_file" "$csv" ;;
    *)
      usage >&2
      exit 1 ;;
  esac
  cleanup
}

parse_inputs() {
  while getopts "a:bcde:xm:s:" opt; do
      case $opt in
          a)  application=${OPTARG} ;;
          b)  include_backup=1 ;;
          c)  include_images_in_code=1 ;;
          d)  dryrun=1 ;;
          e)  environment=${OPTARG} ;;
          x)  include_images_on_ec2=0 ;; # for testing
          m)  months=${OPTARG} ;;
          s)  aws_cmd_file=${OPTARG} ;;
          :)  echo "Error: option ${OPTARG} requires an argument" ;;
          ?)
              echo "Invalid option: ${OPTARG}" >&2
              echo >&2
              usage >&2
              exit 1
              ;;
      esac
  done
  shift $((OPTIND-1))

  if [[ -n $2 ]]; then  
    echo "Unexpected argument: $1 $2"
    usage >&2
    exit 1
  fi

  action=$1
  if [[ "$application" == "core-shared-services" ]]; then 
    if [[ -n "$environment" ]]; then 
      profile="--profile $application-$environment"
    else
      echo "for core-shared-services need to specify environment"
      exit 1
    fi
  fi
}

set_date_cmd(){
  if [[ "$(uname)" == "Darwin" ]]; then
    if command -v gdate >/dev/null 2>&1; then
      date_cmd="gdate"
    else
      echo "exiting. First you need to run: brew install core-utils"
      exit 1
    fi
  else
    date_cmd="date"
  fi
  now=$($date_cmd +%s)
}

date_minus_month() {
  local month=$1
  shift
  $date_cmd -d "-${month} month" "$@"
}

date_minus_year() {
  local year=$1
  shift
  $date_cmd -d "-${year} year" "$@"
}

get_date_filter() {
  local date_filter
  local i
  local m=$1
  local m1=$(date_minus_month "$m" "+%m")
  local m2=${m1#0}
  local m3=$((m+m2))

  if ((m2<12)); then
    for ((i=m;i<m3;i++)); do
      date_filter=${date_filter}$(date_minus_month "$i" "+%Y-%m-*"),
    done
  else
    date_filter=${date_filter}$(date_minus_month "$m2" "+%Y-*"),
  fi
  date_filter=${date_filter}$(date_minus_month $((m3+1)) "+%Y-*"),
  date_filter=${date_filter}$(date_minus_month $((m3+13)) "+%Y-*"),
  date_filter=${date_filter}$(date_minus_month $((m3+25)) "+%Y-*")
  echo "$date_filter"
}

# Normalize, drop CRLF/blank lines, sort deterministically
clean_sort() {
  sed -e 's/\r$//' -e '/^$/d' | LC_ALL=C sort -u
}

# Parse AWS TEXT (tab-delimited) to CSV while preserving AMI names with spaces
aws_text_to_csv() {
  awk -F'\t' 'BEGIN{OFS=","} {
    name=$5;
    if (NF>5) { for(i=6;i<=NF;i++){ name=name " " $i } }
    gsub(/\r/,"",name);
    print $1,$2,$3,$4,name
  }'
}

get_account_images_csv() {
  local months=$1
  local include_backup=$2  

  local filters=''
  if [[ -n $months ]]; then
    local date_filter
    date_filter=$(get_date_filter "$months")
    filters="--filters Name=creation-date,Values=$date_filter"
  fi

  local out
  out=$(aws ec2 describe-images $filters $profile \
           --owners self \
           --query 'Images[].[ImageId, OwnerId, CreationDate, Public, Name]' \
           --output text 2> $aws_error_log | aws_text_to_csv)
  check_aws_error

  if [[ $include_backup == 0 ]]; then
    echo "$out" | grep -v 'AwsBackup' || true
  else
    echo "$out"
  fi
}

get_usage_report_csv() {
  mapfile -t account_images < <(get_account_images_csv $months $include_backup)
  for ami in "${account_images[@]}"; do
    IFS=',' read -r image_id owner_id creation_date public name <<< "$ami"

    report_id=$(aws ec2 create-image-usage-report $profile \
                  --image-id "$image_id" \
                  --resource-types ResourceType=ec2:Instance 'ResourceType=ec2:LaunchTemplate,ResourceTypeOptions=[{OptionName=version-depth,OptionValues=100}]' \
                  --output text)
    report_usage=$(aws ec2 describe-image-usage-report-entries $profile \
                     --report-id "$report_id" \
                     --output text || true)
    [[ -n $report_usage ]] && echo "$ami"
  done
}

get_ec2_instance_images_csv() {
  if [[ "$application" == "core-shared-services-production" ]]; then
    get_usage_report_csv
  else
    mapfile -t ids < <(aws ec2 describe-instances $profile \
            --query "Reservations[*].Instances[*].ImageId" \
            --output text 2> $aws_error_log | tr '\t' '\n' | sed '/^$/d' | sort -u)
    check_aws_error
    [[ ${#ids[@]} -eq 0 ]] && return 0
    aws ec2 describe-images $profile \
            --image-ids "${ids[@]}" \
            --query 'Images[].[ImageId, OwnerId, CreationDate, Public, Name]' \
            --output text 2> $aws_error_log | aws_text_to_csv
    check_aws_error
  fi
}

get_code_image_names() {
  local app=$1
  local envdir
  local tf_files

  if [[ "$app" == "core-shared-services-production" ]]; then 
    envdir=$(dirname "$0")/../../modernisation-platform/terraform/environments/core-shared-services
  else 
    envdir=$(dirname "$0")/../../modernisation-platform-environments/terraform/environments/$app
  fi
  if [[ ! -d "$envdir" ]]; then
    echo "Cannot find $envdir" >&2
    exit 1
  fi
  if [[ -n $app ]]; then
    tf_files="${envdir}/*.tf" 
  else
    tf_files="${envdir}/*/*.tf"
  fi
  grep -Eo 'ami_name[[:space:]]*=[[:space:]]*"[^"]*"' $tf_files | cut -d\" -f2 | sort -u | grep -vF '*' | sort -u || true
}

get_code_csv() {
  local ami code
  ami=$(get_account_images_csv 0 | LC_ALL=C sort -t, -k5,5)
  code=$(get_code_image_names "$1")
  join -o 1.1,1.2,1.3,1.4,1.5  -t, -1 5 <(echo "$ami") <(echo "$code" | LC_ALL=C sort) | clean_sort
}

get_ec2_and_code_csv() {
  local ami code amicode ec2
  ami=$(get_account_images_csv 0 | LC_ALL=C sort -t, -k5,5)
  code=$(get_code_image_names "$1")
  amicode=$(join -o 1.1,1.2,1.3,1.4,1.5  -t, -1 5 <(echo "$ami") <(echo "$code" | LC_ALL=C sort) | LC_ALL=C sort)
  ec2=$(get_ec2_instance_images_csv | LC_ALL=C sort)
  comm <(echo "$amicode") <(echo "$ec2") | tr -d ' \t' | clean_sort
}

get_in_use_images_csv() {
  local include_ec2=$1
  local include_code=$2
  local app=$3
  local csv_ec2=""
  local csv_code=""
  if [[ "$include_ec2" == "1" ]]; then
    csv_ec2=$(get_ec2_instance_images_csv | clean_sort)
  fi
  if [[ "$include_code" == "1" ]]; then
    csv_code=$(get_code_csv "$app" | clean_sort)
  fi
  printf "%s\n%s\n" "$csv_ec2" "$csv_code" | clean_sort
}

get_images_to_delete_csv() {
  local include_ec2=$1
  local include_code=$2
  local app=$3
  local months=$4
  local include_backup=$5

  local account in_use
  account=$(get_account_images_csv "$months" "$include_backup" | clean_sort)
  in_use=$(get_in_use_images_csv "$include_ec2" "$include_code" "$app" | clean_sort)
  comm -23 <(echo "$account") <(echo "$in_use") || true
}

delete_images() {
  local dryrun=$1
  local aws_cmd_file=$2
  local csv=$3
  [[ -z "$aws_cmd_file" ]] && aws_cmd_file="ami_delete_commands.sh"

  local tmp
  tmp=$(mktemp)

  {
    echo "#!/bin/bash"
    echo "# Generated AWS deregistration commands"
  } > "$tmp"

  local count=0
  while IFS=',' read -r image_id owner_id creation_date public name; do
    [[ -z "$image_id" ]] && continue
    echo "aws ec2 deregister-image --image-id $image_id $profile" >> "$tmp"
    ((count++))
  done <<< "$csv"

  {
    echo ""
    echo "# Summary: $count AMI(s) slated for deregistration"
  } >> "$tmp"

  chmod +x "$tmp"
  mv "$tmp" "$aws_cmd_file"

  echo "Found $count AMI(s) to deregister."
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
}

check_aws_error() {
  if grep -q 'Error' "$aws_error_log" 2>/dev/null; then
    echo "AWS CLI error detected:" >&2
    cat "$aws_error_log" >&2
    exit 1
  fi
}

cleanup() {
  rm -f "$aws_error_log" || true
}

main "$@"

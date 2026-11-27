#!/usr/bin/env bash

# Read-only readiness checks for Grafana Cloud PDC in the Observability Platform AWS account that the
# shell is authenticated to. It reads only AWS resource metadata, never secret values: it does not call
# secretsmanager get-secret-value or read the rotation journal, and it prints only names, states,
# counts and non-secret tags.
#
# Usage: bash contrib/check-pdc-readiness.sh <slack|runtime|credentials|accounts>
#
#   slack        Before the first apply: the MoJ Slack workspace is authorised in Amazon Q Developer
#                in chat applications. After the apply it also checks the alert channel configuration.
#   runtime      After the first apply: the rotator Lambda, journal table, alarms and alert topic.
#   credentials  Before onboarding accounts: both rotator credentials hold exactly one AWSCURRENT version.
#   accounts     After onboarding: each grafana-cloud/pdc/<account ID> secret, enrolment rule and alarm.
#
# Optional environment variables:
#   AWS_REGION             Region of the central resources (default eu-west-2)
#   PDC_ENVIRONMENT        Environment suffix of the alert topic (default production)
#   SLACK_TEAM_ID          Slack workspace (default T02DYEB3A)
#   SLACK_CHANNEL_ID       Alert channel (default C06RA6C52TW, the production channel)
#   EXPECTED_STACK_ID      Grafana Cloud stack ID that tagged secrets must name (default 1907875)
#   EXPECTED_IMAGE_DIGEST  If set, the deployed Lambda image must use this sha256 digest
#   CHATBOT_REGION         Region of the Amazon Q Developer API (default us-east-2)
# Exit status is non-zero if any check fails.

set -uo pipefail

REGION="${AWS_REGION:-eu-west-2}"
CHATBOT_REGION="${CHATBOT_REGION:-us-east-2}"
ENVIRONMENT="${PDC_ENVIRONMENT:-production}"
SLACK_TEAM_ID="${SLACK_TEAM_ID:-T02DYEB3A}"
SLACK_CHANNEL_ID="${SLACK_CHANNEL_ID:-C06RA6C52TW}"
EXPECTED_STACK_ID="${EXPECTED_STACK_ID:-1907875}"
FUNCTION_NAME="grafana-pdc-token-rotator"
failures=0

pass() { printf 'PASS  %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*"; }
fail() {
  printf 'FAIL  %s\n' "$*"
  failures=$((failures + 1))
}

# Prints the text result of a read-only AWS CLI call, or nothing if the call fails.
query() {
  local region="$1" result
  shift
  result="$(aws --region "${region}" --output text "$@" 2>/dev/null)" || return 0
  [[ "${result}" == "None" ]] || printf '%s' "${result}"
}

secret_current_count() {
  # shellcheck disable=SC2016 # JMESPath literals use backticks
  query "${REGION}" secretsmanager describe-secret --secret-id "$1" \
    --query 'length(values(VersionIdsToStages || `{}`)[?contains(@, `AWSCURRENT`)])'
}

check_slack() {
  local workspace channel
  workspace="$(query "${CHATBOT_REGION}" chatbot describe-slack-workspaces \
    --query "SlackWorkspaces[?SlackTeamId=='${SLACK_TEAM_ID}'].SlackTeamId")"
  if [[ "${workspace}" == "${SLACK_TEAM_ID}" ]]; then
    pass "Slack workspace ${SLACK_TEAM_ID} is authorised in Amazon Q Developer in this account"
  else
    fail "Slack workspace ${SLACK_TEAM_ID} is not authorised (or this role cannot read it). Authorise it in the Amazon Q Developer console, then run /invite @Amazon Q in the alert channel"
  fi
  channel="$(query "${CHATBOT_REGION}" chatbot describe-slack-channel-configurations \
    --query "SlackChannelConfigurations[?SlackChannelId=='${SLACK_CHANNEL_ID}'].ConfigurationName")"
  if [[ -n "${channel}" ]]; then
    pass "Alert channel ${SLACK_CHANNEL_ID} has a channel configuration"
  else
    warn "No channel configuration for ${SLACK_CHANNEL_ID} yet (expected before the first apply)"
  fi
}

check_runtime() {
  local state concurrency image_uri table topic rule alarm
  state="$(query "${REGION}" lambda get-function-configuration --function-name "${FUNCTION_NAME}" \
    --query '[PackageType, State, LastUpdateStatus]')"
  if [[ "${state}" =~ ^Image[[:space:]]+Active[[:space:]]+Successful$ ]]; then
    pass "Lambda ${FUNCTION_NAME} is an active container image function"
  else
    fail "Lambda ${FUNCTION_NAME} is missing or not Image/Active/Successful (got: ${state:-nothing})"
  fi
  concurrency="$(query "${REGION}" lambda get-function-concurrency --function-name "${FUNCTION_NAME}" \
    --query ReservedConcurrentExecutions)"
  if [[ "${concurrency}" == "1" ]]; then
    pass "Lambda reserved concurrency is 1"
  else
    fail "Lambda reserved concurrency should be 1 (got: ${concurrency:-nothing})"
  fi
  image_uri="$(query "${REGION}" lambda get-function --function-name "${FUNCTION_NAME}" \
    --query 'Code.ResolvedImageUri')"
  if [[ -z "${EXPECTED_IMAGE_DIGEST:-}" ]]; then
    warn "EXPECTED_IMAGE_DIGEST not set: image ${image_uri##*@} is unchecked"
  elif [[ "${image_uri}" == *"@${EXPECTED_IMAGE_DIGEST}" ]]; then
    pass "Lambda runs the expected image digest"
  else
    fail "Lambda image digest is ${image_uri##*@}, expected ${EXPECTED_IMAGE_DIGEST}"
  fi
  table="$(query "${REGION}" dynamodb describe-table --table-name "${FUNCTION_NAME}-state" \
    --query '[Table.TableStatus, Table.DeletionProtectionEnabled]')"
  if [[ "${table}" =~ ^ACTIVE[[:space:]]+True$ ]]; then
    pass "Rotation journal table is ACTIVE with deletion protection"
  else
    fail "Rotation journal table is missing, inactive or unprotected (got: ${table:-nothing})"
  fi
  topic="$(query "${REGION}" sns list-topics \
    --query "Topics[?ends_with(TopicArn, ':grafana-pdc-rotation-failures-${ENVIRONMENT}')].TopicArn")"
  if [[ -n "${topic}" ]]; then
    pass "Failure alert topic exists"
    if [[ -n "$(query "${REGION}" sns get-topic-attributes --topic-arn "${topic}" --query 'Attributes.KmsMasterKeyId')" ]]; then
      pass "Failure alert topic is encrypted"
    else
      fail "Failure alert topic is not encrypted"
    fi
  else
    fail "Failure alert topic grafana-pdc-rotation-failures-${ENVIRONMENT} not found"
  fi
  alarm="$(query "${REGION}" cloudwatch describe-alarms --alarm-names "${FUNCTION_NAME}-errors" \
    --query 'MetricAlarms[0].StateValue')"
  if [[ "${alarm}" == "OK" || "${alarm}" == "INSUFFICIENT_DATA" ]]; then
    pass "Lambda errors alarm exists and is ${alarm}"
  else
    fail "Lambda errors alarm is missing or in ALARM (got: ${alarm:-nothing})"
  fi
  rule="$(query "${REGION}" events describe-rule --name "${FUNCTION_NAME}-rotation-failed" --query State)"
  if [[ "${rule}" == "ENABLED" ]]; then
    pass "RotationFailed rule is ENABLED"
  else
    fail "RotationFailed rule is missing or disabled (got: ${rule:-nothing})"
  fi
  check_slack
}

check_credentials() {
  local name count
  for name in management-token stack-query-token; do
    count="$(secret_current_count "grafana-cloud/pdc-token-rotator/${name}")"
    case "${count}" in
      1) pass "${name} has exactly one AWSCURRENT version" ;;
      0) fail "${name} exists but holds no value: upload it before onboarding accounts" ;;
      *) fail "${name} is missing or unreadable (got: ${count:-nothing})" ;;
    esac
  done
}

check_accounts() {
  local names name id stack tenant current bootstrapped=0 total=0 rules rule targets alarms alarm alarm_state count_rules=0 alarming
  names="$(query "${REGION}" secretsmanager list-secrets \
    --filters Key=name,Values=grafana-cloud/pdc/ --query 'SecretList[].Name')"
  for name in ${names}; do
    [[ "${name}" =~ ^grafana-cloud/pdc/([0-9]{12})$ ]] || continue
    id="${BASH_REMATCH[1]}"
    total=$((total + 1))
    stack="$(query "${REGION}" secretsmanager describe-secret --secret-id "${name}" \
      --query "Tags[?Key=='pdc:stack-id'].Value | [0]")"
    tenant="$(query "${REGION}" secretsmanager describe-secret --secret-id "${name}" \
      --query "Tags[?Key=='pdc:tenant-account-id'].Value | [0]")"
    current="$(secret_current_count "${name}")"
    if [[ "${stack}" != "${EXPECTED_STACK_ID}" || "${tenant}" != "${id}" ]]; then
      fail "${id}: tags name stack ${stack:-none} and tenant ${tenant:-none}, expected ${EXPECTED_STACK_ID} and ${id}"
    elif [[ "${current}" == "1" ]]; then
      bootstrapped=$((bootstrapped + 1))
      pass "${id}: stack ${stack}, single AWSCURRENT version (first issuance completed)"
    else
      fail "${id}: ${current:-unknown} AWSCURRENT versions: bootstrap has not completed"
    fi
  done
  if ((total == 0)); then
    fail "No grafana-cloud/pdc/<account ID> secrets found"
  else
    echo "Bootstrapped ${bootstrapped} of ${total} account secrets"
  fi

  # shellcheck disable=SC2016 # JMESPath literals use backticks
  rules="$(query "${REGION}" events list-rules --name-prefix pdc-enrol- --query 'Rules[?State==`ENABLED`].Name')"
  for rule in ${rules}; do
    count_rules=$((count_rules + 1))
    targets="$(query "${REGION}" events list-targets-by-rule --rule "${rule}" --query 'length(Targets)')"
    [[ "${targets}" == "1" ]] || fail "${rule}: expected one target (got: ${targets:-nothing})"
  done
  if ((count_rules == total)); then
    pass "${count_rules} enabled hourly enrolment rules for ${total} secrets"
  else
    fail "${count_rules} enabled enrolment rules for ${total} secrets"
  fi

  alarms="$(query "${REGION}" cloudwatch describe-alarms --alarm-name-prefix pdc-enrol- \
    --query 'MetricAlarms[].[AlarmName, StateValue]')"
  alarming=0
  while read -r alarm alarm_state; do
    if [[ "${alarm_state}" == "ALARM" ]]; then
      alarming=$((alarming + 1))
      fail "${alarm} is in ALARM"
    fi
  done <<<"${alarms}"
  ((alarming > 0)) || pass "No enrolment delivery alarm is in ALARM"
}

case "${1:-}" in
  slack) check_slack ;;
  runtime) check_runtime ;;
  credentials) check_credentials ;;
  accounts) check_accounts ;;
  *)
    sed -n '3,25p' "$0"
    exit 2
    ;;
esac

if ((failures > 0)); then
  echo "${failures} check(s) failed"
  exit 1
fi

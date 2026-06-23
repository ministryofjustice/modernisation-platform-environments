#!/bin/bash
set -euo pipefail

# WAF demo scenario validation script
# Tests each WAF configuration with curl commands

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Hostnames (derived from test_workload.tf locals)
CLUSTER_NAME="cp-2206-0911"
CLUSTER_BASE_DOMAIN="development.container-platform.service.justice.gov.uk"

ENFORCE_HOST="waf-enforce.${CLUSTER_NAME}.${CLUSTER_BASE_DOMAIN}"
DETECT_HOST="waf-detect.${CLUSTER_NAME}.${CLUSTER_BASE_DOMAIN}"
INHERIT_HOST="waf-inherit.${CLUSTER_NAME}.${CLUSTER_BASE_DOMAIN}"
DISABLED_HOST="waf-disabled.${CLUSTER_NAME}.${CLUSTER_BASE_DOMAIN}"
TUNED_HOST="waf-tuned.${CLUSTER_NAME}.${CLUSTER_BASE_DOMAIN}"
CUSTOM_HOST="waf-custom.${CLUSTER_NAME}.${CLUSTER_BASE_DOMAIN}"

SQL_INJECTION="?id=1'+OR+'1'%3D'1"

echo -e "${BOLD}==========================================${RESET}"
echo -e "${BOLD}  WAF Demo Scenario Validation${RESET}"
echo -e "${BOLD}==========================================${RESET}"
echo ""

# Function to run a test
run_test() {
  local name=$1
  local url=$2
  local expected=$3

  echo -e "  ${CYAN}Test:${RESET} $name"
  echo -e "  ${CYAN}URL:${RESET}  $url"
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" "$url" || true)
  if [[ "$code" == "000" ]]; then
    echo -e "  ${YELLOW}Result: HTTP 000 (connection failed – DNS not propagated or workload not deployed)${RESET}"
  elif [[ "$code" == 2* ]]; then
    echo -e "  ${GREEN}Result: HTTP $code${RESET}"
  elif [[ "$code" == 403 ]]; then
    echo -e "  ${RED}Result: HTTP $code (blocked)${RESET}"
  else
    echo -e "  ${YELLOW}Result: HTTP $code${RESET}"
  fi
  echo ""
}

# waf_inherit: No route policy – cluster enforcement applies
echo ""
echo -e "${BOLD}1. WAF INHERIT${RESET} – Vanilla, no route policy, cluster enforcement applies"
echo -e "${BOLD}---------------------------------------------${RESET}"
run_test "SQL injection (blocked by cluster enforcement)" "https://${INHERIT_HOST}/${SQL_INJECTION}" "403 Forbidden"

# waf_detect: DetectionOnly – overrides cluster enforcement
echo ""
echo -e "${BOLD}2. WAF DETECT${RESET} – DetectionOnly – overrides cluster enforcement, logs only"
echo -e "${BOLD}---------------------------------------------${RESET}"
run_test "SQL injection logged, not blocked" "https://${DETECT_HOST}/${SQL_INJECTION}" "200 OK"

# waf_disabled: SecRuleEngine Off – escape hatch from cluster enforcement
echo ""
echo -e "${BOLD}3. WAF DISABLED${RESET} – SecRuleEngine Off – escape hatch from cluster enforcement"
echo -e "${BOLD}---------------------------------------------${RESET}"
run_test "SQL injection allowed (WAF off)" "https://${DISABLED_HOST}/${SQL_INJECTION}" "200 OK"

# waf_tuned: Enforce + rule exclusion on specific param
echo ""
echo -e "${BOLD}4. WAF TUNED${RESET} – Enforce + targeted rule exclusion on search param"
echo -e "${BOLD}---------------------------------------------${RESET}"
run_test "SQL injection on id param (blocked)" "https://${TUNED_HOST}/${SQL_INJECTION}" "403 Forbidden"
run_test "SQL injection on search param (allowed)" "https://${TUNED_HOST}/?search=1'+OR+'1'%3D'1" "200 OK"

# waf_custom: Enforce + custom rule
echo ""
echo -e "${BOLD}5. WAF CUSTOM${RESET} – Enforce + custom /admin block rule"
echo -e "${BOLD}---------------------------------------------${RESET}"
run_test "Clean request" "https://${CUSTOM_HOST}/" "200 OK"
run_test "Custom rule blocks /admin" "https://${CUSTOM_HOST}/admin" "403 Forbidden"

echo -e "${BOLD}==========================================${RESET}"
echo -e "${GREEN}${BOLD}  Validation complete!${RESET}"
echo -e "${BOLD}==========================================${RESET}"
echo ""
echo -e "To watch Coraza logs in real-time, run:"
echo -e "  ${CYAN}./tail-coraza-logs.sh${RESET}"

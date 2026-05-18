#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="ai-gateway"
BOLD="\033[1m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
RESET="\033[0m"

RUN_ALL=true
RUN_DATABASE=false
RUN_ELASTICACHE=false
RUN_SECRETS=false

usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "  Run with no flags to execute the full troubleshooting report."
  echo ""
  echo "Options:"
  echo "  --database      Test database connectivity and configuration"
  echo "  --elasticache   Test ElastiCache connectivity and configuration"
  echo "  --secrets       Check and compare all secrets (AWS + K8s)"
  echo "  --help          Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0                         # Full report"
  echo "  $0 --database              # Database checks only"
  echo "  $0 --secrets --database    # Secrets and database checks"
  exit 0
}

parse_args() {
  if [[ $# -eq 0 ]]; then
    return
  fi

  RUN_ALL=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --database)
        RUN_DATABASE=true
        shift
        ;;
      --elasticache)
        RUN_ELASTICACHE=true
        shift
        ;;
      --secrets)
        RUN_SECRETS=true
        shift
        ;;
      --help|-h)
        usage
        ;;
      *)
        echo "Unknown option: $1"
        usage
        ;;
    esac
  done
}

divider() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BOLD}$1${RESET}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""
}

check_pass() {
  echo -e "  ${GREEN}✓${RESET} $1"
}

check_fail() {
  echo -e "  ${RED}✗${RESET} $1"
}

check_warn() {
  echo -e "  ${YELLOW}!${RESET} $1"
}

check_placeholder() {
  echo -e "  ${YELLOW}⚠${RESET} $1"
}

check_prerequisites() {
  divider "Prerequisites"

  local missing=0
  for cmd in kubectl aws helm jq; do
    if command -v "$cmd" &>/dev/null; then
      check_pass "$cmd is available"
    else
      check_fail "$cmd is not installed"
      missing=1
    fi
  done

  if [[ $missing -eq 1 ]]; then
    echo ""
    check_fail "Missing prerequisites. Install the above tools and try again."
    exit 1
  fi

  if kubectl auth can-i get pods -n "$NAMESPACE" &>/dev/null; then
    check_pass "kubectl has access to namespace $NAMESPACE"
  else
    check_fail "kubectl cannot access namespace $NAMESPACE — check your kubeconfig/context"
    exit 1
  fi
}

check_namespace() {
  divider "Namespace"

  if kubectl get namespace "$NAMESPACE" &>/dev/null; then
    check_pass "Namespace $NAMESPACE exists"
    echo ""
    echo "  Labels:"
    kubectl get namespace "$NAMESPACE" -o json | jq -r '.metadata.labels // {} | to_entries[] | "    \(.key) = \(.value)"'
  else
    check_fail "Namespace $NAMESPACE does not exist"
  fi
}

check_helm_releases() {
  divider "Helm Releases"

  local releases
  releases=$(helm list -n "$NAMESPACE" -o json 2>/dev/null || echo "[]")

  if [[ "$releases" == "[]" ]]; then
    check_fail "No Helm releases found in namespace $NAMESPACE"
    return
  fi

  echo "$releases" | jq -r '.[] | "\(.name)|\(.chart)|\(.app_version)|\(.status)|\(.updated)"' | while IFS='|' read -r name chart app_version status updated; do
    if [[ "$status" == "deployed" ]]; then
      check_pass "$name"
    else
      check_fail "$name (status: $status)"
    fi
    echo "         Chart: $chart"
    echo "         App Version: $app_version"
    echo "         Updated: $updated"
    echo ""
  done
}

check_pods() {
  divider "Pods"

  local pods
  pods=$(kubectl get pods -n "$NAMESPACE" -o json 2>/dev/null)

  if [[ $(echo "$pods" | jq '.items | length') -eq 0 ]]; then
    check_fail "No pods found in namespace $NAMESPACE"
    return
  fi

  echo "$pods" | jq -r '.items[] | "\(.metadata.name)|\(.status.phase)|\(.status.containerStatuses // [] | map(select(.ready == true)) | length)/\(.status.containerStatuses // [] | length)|\(.metadata.creationTimestamp)"' | while IFS='|' read -r name phase ready created; do
    if [[ "$phase" == "Running" ]]; then
      check_pass "$name  [$phase]  Ready: $ready  Age: $created"
    else
      check_fail "$name  [$phase]  Ready: $ready  Age: $created"
    fi
  done

  echo ""
  echo -e "${BOLD}  Restart counts:${RESET}"
  echo "$pods" | jq -r '.items[] | .metadata.name as $pod | (.status.containerStatuses // [])[] | "    \($pod)/\(.name): \(.restartCount) restarts"'
}

check_kubernetes_secrets() {
  divider "Kubernetes Secrets (namespace: $NAMESPACE)"

  local expected_secrets=(
    "litellm-master-key"
    "litellm-license"
    "litellm-entra-id"
    "justiceai-azure-openai"
    "azure-openai"
    "aurora"
    "elasticache"
  )

  for secret in "${expected_secrets[@]}"; do
    if kubectl get secret "$secret" -n "$NAMESPACE" &>/dev/null; then
      check_pass "$secret"
      kubectl get secret "$secret" -n "$NAMESPACE" -o json | jq -r '.data // {} | to_entries[] | "         \(.key) = \(.value | @base64d)"'
    else
      check_fail "$secret — NOT FOUND"
    fi
    echo ""
  done
}

check_external_secrets() {
  divider "External Secrets (sync status)"

  local external_secrets
  external_secrets=$(kubectl get externalsecrets -n "$NAMESPACE" -o json 2>/dev/null || echo '{"items":[]}')

  if [[ $(echo "$external_secrets" | jq '.items | length') -eq 0 ]]; then
    check_warn "No ExternalSecrets found in namespace $NAMESPACE"
    return
  fi

  echo "$external_secrets" | jq -r '.items[] | "\(.metadata.name)|\(.status.conditions // [] | map(select(.type == "Ready")) | .[0].status // "Unknown")|\(.status.conditions // [] | map(select(.type == "Ready")) | .[0].message // "No message")"' | while IFS='|' read -r name status message; do
    if [[ "$status" == "True" ]]; then
      check_pass "$name — synced"
    else
      check_fail "$name — $message"
    fi
  done
}

check_aws_secrets() {
  divider "AWS Secrets Manager"

  local expected_aws_secrets=(
    "ai-gateway/litellm-license"
    "ai-gateway/litellm-entra-id"
    "ai-gateway/justiceai-azure-openai"
    "ai-gateway/azure-openai"
    "ai-gateway/aurora"
    "ai-gateway/elasticache"
  )

  for secret in "${expected_aws_secrets[@]}"; do
    local value
    if value=$(aws secretsmanager get-secret-value --secret-id "$secret" --query 'SecretString' --output text 2>/dev/null); then
      check_pass "$secret"
      if echo "$value" | jq . &>/dev/null; then
        echo "$value" | jq -r 'to_entries[] | "         \(.key) = \(.value)"'
      else
        echo "         value = $value"
      fi
    else
      check_fail "$secret — NOT FOUND or insufficient permissions"
    fi
    echo ""
  done
}

check_database_connectivity() {
  divider "Database (Aurora PostgreSQL)"

  local aurora_secret
  if ! aurora_secret=$(kubectl get secret aurora -n "$NAMESPACE" -o json 2>/dev/null); then
    check_fail "Cannot read aurora secret from Kubernetes"
    return
  fi

  local db_host db_port db_name db_user
  db_host=$(echo "$aurora_secret" | jq -r '.data.host' | base64 -d 2>/dev/null || echo "")
  db_port=$(echo "$aurora_secret" | jq -r '.data.port' | base64 -d 2>/dev/null || echo "")
  db_name=$(echo "$aurora_secret" | jq -r '.data.dbname' | base64 -d 2>/dev/null || echo "")
  db_user=$(echo "$aurora_secret" | jq -r '.data.username' | base64 -d 2>/dev/null || echo "")

  echo "  Host:     ${db_host:-NOT SET}"
  echo "  Port:     ${db_port:-NOT SET}"
  echo "  Database: ${db_name:-NOT SET}"
  echo "  Username: ${db_user:-NOT SET}"
  echo "  Password: $(if echo "$aurora_secret" | jq -e '.data.password' &>/dev/null; then echo "SET"; else echo "NOT SET"; fi)"
  echo ""

  local empty_vars=()
  [[ -z "$db_host" ]] && empty_vars+=("host")
  [[ -z "$db_port" ]] && empty_vars+=("port")
  [[ -z "$db_name" ]] && empty_vars+=("dbname")
  [[ -z "$db_user" ]] && empty_vars+=("username")

  if [[ ${#empty_vars[@]} -gt 0 ]]; then
    check_fail "Missing database variables: ${empty_vars[*]}"
    return
  else
    check_pass "All database variables are populated"
  fi

  echo ""
  echo -e "${BOLD}  Connectivity test (from a pod in the namespace):${RESET}"

  local test_pod
  test_pod=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=litellm -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

  if [[ -z "$test_pod" ]]; then
    check_warn "No litellm pod available to test database connectivity"
    echo "    Try manually: kubectl run pg-test --rm -it --namespace=$NAMESPACE --image=postgres:17 -- pg_isready -h $db_host -p $db_port"
    return
  fi

  if kubectl exec "$test_pod" -n "$NAMESPACE" -- sh -c "pg_isready -h '$db_host' -p '$db_port' 2>/dev/null" &>/dev/null; then
    check_pass "Database is accepting connections (pg_isready from $test_pod)"
  else
    check_warn "pg_isready not available in pod or database not reachable"
    echo "    Try manually: kubectl run pg-test --rm -it --namespace=$NAMESPACE --image=postgres:17 -- pg_isready -h $db_host -p $db_port"
  fi
}

check_elasticache_connectivity() {
  divider "ElastiCache (Valkey/Redis)"

  local elasticache_secret
  if ! elasticache_secret=$(kubectl get secret elasticache -n "$NAMESPACE" -o json 2>/dev/null); then
    check_fail "Cannot read elasticache secret from Kubernetes"
    return
  fi

  local ec_host ec_port ec_auth
  ec_host=$(echo "$elasticache_secret" | jq -r '.data.primary_endpoint_address' | base64 -d 2>/dev/null || echo "")
  ec_port=$(echo "$elasticache_secret" | jq -r '.data.port' | base64 -d 2>/dev/null || echo "")
  ec_auth=$(echo "$elasticache_secret" | jq -r '.data.auth_token' | base64 -d 2>/dev/null || echo "")

  echo "  Host:       ${ec_host:-NOT SET}"
  echo "  Port:       ${ec_port:-NOT SET}"
  echo "  Auth Token: $(if [[ -n "$ec_auth" ]]; then echo "SET"; else echo "NOT SET"; fi)"
  echo ""

  local empty_vars=()
  [[ -z "$ec_host" ]] && empty_vars+=("primary_endpoint_address")
  [[ -z "$ec_port" ]] && empty_vars+=("port")
  [[ -z "$ec_auth" ]] && empty_vars+=("auth_token")

  if [[ ${#empty_vars[@]} -gt 0 ]]; then
    check_fail "Missing ElastiCache variables: ${empty_vars[*]}"
    return
  else
    check_pass "All ElastiCache variables are populated"
  fi

  echo ""
  echo -e "${BOLD}  Connectivity test (from a pod in the namespace):${RESET}"

  local test_pod
  test_pod=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=litellm -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

  if [[ -z "$test_pod" ]]; then
    check_warn "No litellm pod available to test ElastiCache connectivity"
    echo "    Try manually: kubectl run redis-test --rm -it --namespace=$NAMESPACE --image=redis:7 -- redis-cli -h $ec_host -p $ec_port --tls -a <auth_token> PING"
    return
  fi

  local ping_result
  if ping_result=$(kubectl exec "$test_pod" -n "$NAMESPACE" -- sh -c "echo PING | timeout 5 openssl s_client -connect '${ec_host}:${ec_port}' -quiet 2>/dev/null" 2>/dev/null); then
    if echo "$ping_result" | grep -q "PONG"; then
      check_pass "ElastiCache responded with PONG (TLS connection from $test_pod)"
    else
      check_warn "Connected to ElastiCache but did not receive PONG (may need AUTH)"
    fi
  else
    if kubectl exec "$test_pod" -n "$NAMESPACE" -- sh -c "timeout 3 sh -c 'echo > /dev/tcp/${ec_host}/${ec_port}'" &>/dev/null; then
      check_pass "TCP connection to ElastiCache succeeded (port $ec_port is open)"
      check_warn "Could not verify PING/PONG — AUTH or TLS handshake may be required"
    else
      check_fail "Cannot connect to ElastiCache at ${ec_host}:${ec_port}"
      echo "    Try manually: kubectl run redis-test --rm -it --namespace=$NAMESPACE --image=redis:7 -- redis-cli -h $ec_host -p $ec_port --tls -a <auth_token> PING"
    fi
  fi
}

check_service_account() {
  divider "Service Account"

  local sa
  if sa=$(kubectl get serviceaccount litellm -n "$NAMESPACE" -o json 2>/dev/null); then
    local role_arn
    role_arn=$(echo "$sa" | jq -r '.metadata.annotations["eks.amazonaws.com/role-arn"] // "NOT SET"')
    check_pass "Service account 'litellm' exists"
    echo "         IAM Role ARN: $role_arn"
  else
    check_fail "Service account 'litellm' not found"
  fi
}

check_gateway_and_routes() {
  divider "Gateway API Resources"

  echo -e "${BOLD}  Gateways:${RESET}"
  if kubectl get gateways -n "$NAMESPACE" &>/dev/null; then
    kubectl get gateways -n "$NAMESPACE" -o wide 2>/dev/null | sed 's/^/    /'
  else
    check_warn "No Gateway resources found or Gateway API CRDs not installed"
  fi

  echo ""
  echo -e "${BOLD}  HTTPRoutes:${RESET}"
  if kubectl get httproutes -n "$NAMESPACE" &>/dev/null; then
    kubectl get httproutes -n "$NAMESPACE" -o wide 2>/dev/null | sed 's/^/    /'
  else
    check_warn "No HTTPRoute resources found"
  fi
}

check_hpa() {
  divider "Horizontal Pod Autoscaler"

  local hpas
  hpas=$(kubectl get hpa -n "$NAMESPACE" -o json 2>/dev/null || echo '{"items":[]}')

  if [[ $(echo "$hpas" | jq '.items | length') -eq 0 ]]; then
    check_warn "No HPA resources found in namespace $NAMESPACE"
    return
  fi

  echo "$hpas" | jq -r '.items[] | "\(.metadata.name)|\(.spec.minReplicas)|\(.spec.maxReplicas)|\(.status.currentReplicas)|\(.status.currentCPUUtilizationPercentage // "N/A")"' | while IFS='|' read -r name min max current cpu; do
    check_pass "$name  [Min: $min, Max: $max, Current: $current, CPU: ${cpu}%]"
  done
}

check_events() {
  divider "Recent Events (last 30 minutes)"

  local events
  events=$(kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' --field-selector type!=Normal -o json 2>/dev/null || echo '{"items":[]}')

  local event_count
  event_count=$(echo "$events" | jq '.items | length')

  if [[ "$event_count" -eq 0 ]]; then
    check_pass "No warning/error events in namespace $NAMESPACE"
  else
    check_warn "$event_count warning/error event(s) found:"
    echo ""
    echo "$events" | jq -r '.items[-20:] | reverse | .[] | "    \(.lastTimestamp) [\(.reason)] \(.involvedObject.kind)/\(.involvedObject.name): \(.message)"'
  fi

  echo ""
  echo -e "${BOLD}  All recent events:${RESET}"
  kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' 2>/dev/null | tail -20 | sed 's/^/    /'
}

check_pod_logs() {
  divider "Recent Pod Logs (errors/warnings)"

  local pods
  pods=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=litellm -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")

  if [[ -z "$pods" ]]; then
    check_warn "No litellm pods found to check logs"
    return
  fi

  for pod in $pods; do
    echo -e "  ${BOLD}$pod:${RESET}"
    local errors
    errors=$(kubectl logs "$pod" -n "$NAMESPACE" --tail=100 2>/dev/null | grep -iE "(error|exception|traceback|fatal|critical)" | tail -10 || true)
    if [[ -n "$errors" ]]; then
      check_warn "Errors found in logs:"
      echo "$errors" | sed 's/^/      /'
    else
      check_pass "No obvious errors in last 100 log lines"
    fi
    echo ""
  done
}

compare_secrets() {
  divider "Secret Comparison (AWS vs Kubernetes)"

  echo "  Comparing values in AWS Secrets Manager against their synced Kubernetes secrets."
  echo "  A mismatch means the ExternalSecret operator has not synced, or the secret was"
  echo "  manually modified in one location."
  echo ""

  local has_mismatch=0

  # aurora: ai-gateway/aurora <-> k8s secret "aurora"
  compare_secret_pair "ai-gateway/aurora" "aurora" \
    "username:username" \
    "password:password" \
    "host:host" \
    "port:port" \
    "dbname:dbname"

  # elasticache: ai-gateway/elasticache <-> k8s secret "elasticache"
  compare_secret_pair "ai-gateway/elasticache" "elasticache" \
    "primary_endpoint_address:primary_endpoint_address" \
    "auth_token:auth_token" \
    "port:port"

  # litellm-entra-id: ai-gateway/litellm-entra-id <-> k8s secret "litellm-entra-id"
  compare_secret_pair "ai-gateway/litellm-entra-id" "litellm-entra-id" \
    "client_id:MICROSOFT_CLIENT_ID" \
    "client_secret:MICROSOFT_CLIENT_SECRET" \
    "tenant_id:MICROSOFT_TENANT" \
    "proxy_admin_id:PROXY_ADMIN_ID"

  # justiceai-azure-openai: ai-gateway/justiceai-azure-openai <-> k8s secret "justiceai-azure-openai"
  compare_secret_pair "ai-gateway/justiceai-azure-openai" "justiceai-azure-openai" \
    "api_base:AZURE_OPENAI_API_BASE" \
    "api_key:AZURE_OPENAI_API_KEY"

  # azure-openai: ai-gateway/azure-openai <-> k8s secret "azure-openai"
  compare_secret_pair "ai-gateway/azure-openai" "azure-openai" \
    "api_base:AZURE_OPENAI_API_BASE" \
    "api_key:AZURE_OPENAI_API_KEY"

  # litellm-license: ai-gateway/litellm-license <-> k8s secret "litellm-license"
  compare_secret_pair_plain "ai-gateway/litellm-license" "litellm-license" "license"
}

compare_secret_pair() {
  local aws_secret_id="$1"
  local k8s_secret_name="$2"
  shift 2

  echo -e "  ${BOLD}${aws_secret_id} ↔ k8s/${k8s_secret_name}${RESET}"

  local aws_value k8s_secret
  aws_value=$(aws secretsmanager get-secret-value --secret-id "$aws_secret_id" --query 'SecretString' --output text 2>/dev/null || echo "")
  k8s_secret=$(kubectl get secret "$k8s_secret_name" -n "$NAMESPACE" -o json 2>/dev/null || echo "")

  if [[ -z "$aws_value" ]]; then
    check_fail "Cannot retrieve AWS secret: $aws_secret_id"
    echo ""
    return
  fi
  if [[ -z "$k8s_secret" ]]; then
    check_fail "Cannot retrieve K8s secret: $k8s_secret_name"
    echo ""
    return
  fi

  for mapping in "$@"; do
    local aws_key="${mapping%%:*}"
    local k8s_key="${mapping##*:}"

    local aws_val k8s_val
    aws_val=$(echo "$aws_value" | jq -r --arg k "$aws_key" '.[$k] // ""')
    k8s_val=$(echo "$k8s_secret" | jq -r --arg k "$k8s_key" '.data[$k] // ""' | base64 -d 2>/dev/null || echo "")

    if [[ -z "$aws_val" && -z "$k8s_val" ]]; then
      check_warn "$aws_key → $k8s_key: both empty"
    elif [[ "$aws_val" == "$k8s_val" ]]; then
      if [[ "$aws_val" == "CHANGEME" ]]; then
        check_placeholder "$aws_key → $k8s_key: match but value is CHANGEME (placeholder — not a real value!)"
        echo -e "         Value: $aws_val"
      else
        check_pass "$aws_key → $k8s_key: match"
        echo -e "         Value: $aws_val"
      fi
    else
      check_fail "$aws_key → $k8s_key: MISMATCH"
      echo -e "         AWS:  $aws_val"
      echo -e "         K8s:  $k8s_val"
      has_mismatch=1
    fi
  done
  echo ""
}

compare_secret_pair_plain() {
  local aws_secret_id="$1"
  local k8s_secret_name="$2"
  local k8s_key="$3"

  echo -e "  ${BOLD}${aws_secret_id} ↔ k8s/${k8s_secret_name}${RESET}"

  local aws_value k8s_secret
  aws_value=$(aws secretsmanager get-secret-value --secret-id "$aws_secret_id" --query 'SecretString' --output text 2>/dev/null || echo "")
  k8s_secret=$(kubectl get secret "$k8s_secret_name" -n "$NAMESPACE" -o json 2>/dev/null || echo "")

  if [[ -z "$aws_value" ]]; then
    check_fail "Cannot retrieve AWS secret: $aws_secret_id"
    echo ""
    return
  fi
  if [[ -z "$k8s_secret" ]]; then
    check_fail "Cannot retrieve K8s secret: $k8s_secret_name"
    echo ""
    return
  fi

  local k8s_val
  k8s_val=$(echo "$k8s_secret" | jq -r --arg k "$k8s_key" '.data[$k] // ""' | base64 -d 2>/dev/null || echo "")

  if [[ -z "$aws_value" && -z "$k8s_val" ]]; then
    check_warn "value → $k8s_key: both empty"
  elif [[ "$aws_value" == "$k8s_val" ]]; then
    if [[ "$aws_value" == "CHANGEME" ]]; then
      check_placeholder "value → $k8s_key: match but value is CHANGEME (placeholder — not a real value!)"
      echo -e "         Value: $aws_value"
    else
      check_pass "value → $k8s_key: match"
      echo -e "         Value: $aws_value"
    fi
  else
    check_fail "value → $k8s_key: MISMATCH"
    echo -e "         AWS:  $aws_value"
    echo -e "         K8s:  $k8s_val"
  fi
  echo ""
}

check_litellm_health() {
  divider "LiteLLM Health Endpoint"

  local test_pod
  test_pod=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=litellm -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

  if [[ -z "$test_pod" ]]; then
    check_warn "No litellm pod available to test health endpoint"
    return
  fi

  local svc_name="litellm"
  local health_response
  if health_response=$(kubectl exec "$test_pod" -n "$NAMESPACE" -- wget -qO- "http://${svc_name}:4000/health" 2>/dev/null); then
    check_pass "Health endpoint responded"
    echo "    $health_response" | jq . 2>/dev/null | sed 's/^/    /' || echo "    $health_response"
  else
    check_fail "Health endpoint did not respond — service may be unhealthy"
  fi
}

main() {
  parse_args "$@"

  echo ""
  echo -e "${BOLD}╔══════════════════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}║              AI Gateway (LiteLLM) — Troubleshooting Report                  ║${RESET}"
  echo -e "${BOLD}╠══════════════════════════════════════════════════════════════════════════════╣${RESET}"
  echo -e "${BOLD}║  Namespace:  ${NAMESPACE}                                                        ║${RESET}"
  echo -e "${BOLD}║  Timestamp:  $(date -u '+%Y-%m-%d %H:%M:%S UTC')                              ║${RESET}"
  echo -e "${BOLD}║  Context:    $(kubectl config current-context 2>/dev/null | cut -c1-50 || echo "unknown")${RESET}"
  echo -e "${BOLD}╚══════════════════════════════════════════════════════════════════════════════╝${RESET}"

  check_prerequisites

  if [[ "$RUN_ALL" == true ]]; then
    check_namespace
    check_helm_releases
    check_pods
    check_hpa
    check_service_account
    check_kubernetes_secrets
    check_external_secrets
    check_aws_secrets
    check_database_connectivity
    check_elasticache_connectivity
    check_gateway_and_routes
    compare_secrets
    check_litellm_health
    check_pod_logs
    check_events
  else
    if [[ "$RUN_DATABASE" == true ]]; then
      check_database_connectivity
    fi
    if [[ "$RUN_ELASTICACHE" == true ]]; then
      check_elasticache_connectivity
    fi
    if [[ "$RUN_SECRETS" == true ]]; then
      check_kubernetes_secrets
      check_external_secrets
      check_aws_secrets
      compare_secrets
    fi
  fi

  divider "End of Report"
  echo "  For further investigation:"
  echo "    kubectl logs -f -l app.kubernetes.io/name=litellm -n $NAMESPACE"
  echo "    kubectl describe pods -n $NAMESPACE"
  echo "    kubectl get all -n $NAMESPACE"
  echo "    aws rds describe-db-clusters --db-cluster-identifier ai-gateway"
  echo ""
}

main "$@"

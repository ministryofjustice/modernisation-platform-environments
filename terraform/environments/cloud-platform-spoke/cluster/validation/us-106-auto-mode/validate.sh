#!/usr/bin/env bash
###############################################################################
# US-106: EKS Auto Mode Validation Script
#
# Validates all three acceptance criteria for EKS Auto Mode on the spoke
# PoC cluster. Can run all tests or individual ACs.
#
# Usage:
#   ./validate.sh          # Run all tests
#   ./validate.sh ac1      # AC1 only: node provisioning
#   ./validate.sh ac2      # AC2 only: Spot diversification
#   ./validate.sh ac3      # AC3 only: built-in components
#   ./validate.sh cleanup  # Remove all test resources
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/manifests"
RESULTS_DIR="${SCRIPT_DIR}/results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULTS_FILE="${RESULTS_DIR}/validation-${TIMESTAMP}.md"

# Colours for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No colour

mkdir -p "${RESULTS_DIR}"

###############################################################################
# Utility functions
###############################################################################

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[FAIL]${NC} $*"; }

wait_for_pods() {
  local label="$1"
  local expected="$2"
  local timeout="${3:-180}"

  log_info "Waiting up to ${timeout}s for ${expected} pods with label ${label} to reach Running..."
  local elapsed=0
  while [ $elapsed -lt $timeout ]; do
    local running
    running=$(kubectl get pods -l "$label" --no-headers 2>/dev/null | grep -c "Running" || true)
    if [ "$running" -ge "$expected" ]; then
      log_info "All ${expected} pods are Running (took ${elapsed}s)"
      return 0
    fi
    sleep 5
    elapsed=$((elapsed + 5))
  done
  log_error "Timeout: only $(kubectl get pods -l "$label" --no-headers | grep -c "Running" || echo 0)/${expected} pods Running after ${timeout}s"
  return 1
}

wait_for_nodes() {
  local label="$1"
  local min_count="$2"
  local timeout="${3:-180}"

  log_info "Waiting up to ${timeout}s for ${min_count}+ nodes with label ${label}..."
  local elapsed=0
  while [ $elapsed -lt $timeout ]; do
    local ready
    ready=$(kubectl get nodes -l "$label" --no-headers 2>/dev/null | grep -c "Ready" || true)
    if [ "$ready" -ge "$min_count" ]; then
      log_info "Found ${ready} Ready nodes (took ${elapsed}s)"
      return 0
    fi
    sleep 5
    elapsed=$((elapsed + 5))
  done
  log_error "Timeout: only $(kubectl get nodes -l "$label" --no-headers | grep -c "Ready" || echo 0)/${min_count} nodes after ${timeout}s"
  return 1
}

record_result() {
  local ac="$1"
  local status="$2"
  local details="$3"
  echo "| ${ac} | ${status} | ${details} |" >> "${RESULTS_FILE}"
}

###############################################################################
# Pre-flight checks
###############################################################################

preflight() {
  log_info "Running pre-flight checks..."

  if ! kubectl cluster-info &>/dev/null; then
    log_error "Cannot connect to cluster. Ensure kubeconfig is set."
    exit 1
  fi

  local cluster_name
  cluster_name=$(kubectl config current-context)
  log_info "Connected to: ${cluster_name}"

  # Check Auto Mode is enabled
  local compute_config
  compute_config=$(aws eks describe-cluster \
    --name "$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')" \
    --query 'cluster.computeConfig.enabled' \
    --output text 2>/dev/null || echo "UNKNOWN")

  if [ "$compute_config" != "True" ]; then
    log_warn "Auto Mode compute_config.enabled = ${compute_config} (expected True)"
    log_warn "Proceeding anyway — check cluster configuration if tests fail"
  else
    log_info "Auto Mode confirmed enabled"
  fi

  # Initialise results file
  cat > "${RESULTS_FILE}" << EOF
# US-106 Validation Results

**Cluster:** $(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
**Date:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Auto Mode Enabled:** ${compute_config}

## Results

| AC | Status | Details |
|----|--------|---------|
EOF
}

###############################################################################
# AC1: Auto Mode provisions nodes when workload demand increases
###############################################################################

test_ac1() {
  log_info "=== AC1: Node Auto-Provisioning ==="

  # Record initial node count
  local initial_nodes
  initial_nodes=$(kubectl get nodes --no-headers | wc -l | tr -d ' ')
  log_info "Initial node count: ${initial_nodes}"

  # Apply inflate deployment (starts at 0 replicas)
  kubectl apply -f "${MANIFESTS_DIR}/01-inflate-deployment.yaml"

  # Scale to trigger node provisioning
  log_info "Scaling inflate deployment to 10 replicas..."
  kubectl scale deployment us106-inflate --replicas=10

  # Wait for new nodes
  sleep 10  # Give Auto Mode a moment to react
  local start_time=$SECONDS

  if wait_for_pods "app=us106-inflate" 10 300; then
    local elapsed=$((SECONDS - start_time))
    local final_nodes
    final_nodes=$(kubectl get nodes --no-headers | wc -l | tr -d ' ')
    local new_nodes=$((final_nodes - initial_nodes))

    log_info "AC1 PASS: ${new_nodes} new nodes provisioned in ${elapsed}s"
    log_info "Node details:"
    kubectl get nodes -o custom-columns='NAME:.metadata.name,INSTANCE-TYPE:.metadata.labels.node\.kubernetes\.io/instance-type,AGE:.metadata.creationTimestamp' | head -20

    record_result "AC1" "PASS" "${new_nodes} nodes provisioned in ${elapsed}s, all 10 pods Running"
  else
    log_error "AC1 FAIL: Pods did not reach Running state"
    kubectl get pods -l app=us106-inflate
    kubectl get nodes

    record_result "AC1" "FAIL" "Pods did not reach Running within timeout"
  fi

  # Scale back down
  log_info "Scaling down inflate deployment..."
  kubectl scale deployment us106-inflate --replicas=0
}

###############################################################################
# AC2: Spot instance diversification via NodePool
###############################################################################

test_ac2() {
  log_info "=== AC2: Spot Instance Diversification ==="

  # Apply NodePool and Spot workload
  kubectl apply -f "${MANIFESTS_DIR}/02-spot-nodepool.yaml"

  # Wait for NodePool to be ready
  sleep 5
  log_info "NodePool created. Scaling Spot workload to 6 replicas..."
  kubectl scale deployment us106-spot-workload --replicas=6

  # Wait for Spot nodes
  local start_time=$SECONDS

  if wait_for_nodes "capacity-type=spot" 1 300; then
    local elapsed=$((SECONDS - start_time))

    # Check instance type diversity
    log_info "Checking instance type diversification..."
    local instance_types
    instance_types=$(kubectl get nodes -l "capacity-type=spot" \
      -o jsonpath='{range .items[*]}{.metadata.labels.node\.kubernetes\.io/instance-type}{"\n"}{end}' | sort -u)
    local type_count
    type_count=$(echo "$instance_types" | wc -l | tr -d ' ')

    log_info "Spot nodes using ${type_count} distinct instance type(s):"
    echo "$instance_types"

    # Check capacity type labels
    log_info "Node capacity breakdown:"
    kubectl get nodes -o custom-columns=\
'NAME:.metadata.name,INSTANCE-TYPE:.metadata.labels.node\.kubernetes\.io/instance-type,CAPACITY:.metadata.labels.karpenter\.sh/capacity-type,ZONE:.metadata.labels.topology\.kubernetes\.io/zone'

    if wait_for_pods "app=us106-spot-workload" 6 300; then
      log_info "AC2 PASS: Spot nodes provisioned with ${type_count} instance type(s) in ${elapsed}s"
      record_result "AC2" "PASS" "${type_count} instance types on Spot, all pods Running in ${elapsed}s"
    else
      log_warn "AC2 PARTIAL: Spot nodes exist but not all pods Running"
      record_result "AC2" "PARTIAL" "Spot nodes provisioned but some pods pending"
    fi
  else
    log_error "AC2 FAIL: No Spot nodes provisioned"
    kubectl get nodepools
    kubectl get pods -l app=us106-spot-workload
    kubectl describe pods -l app=us106-spot-workload | tail -30

    record_result "AC2" "FAIL" "No Spot nodes provisioned within timeout"
  fi

  # Scale down
  kubectl scale deployment us106-spot-workload --replicas=0
}

###############################################################################
# AC3: Built-in components (LBC, EBS CSI) operational
###############################################################################

test_ac3() {
  log_info "=== AC3: Built-in Components ==="

  # --- EBS CSI Test ---
  log_info "--- AC3a: EBS CSI Driver ---"
  kubectl apply -f "${MANIFESTS_DIR}/03-ebs-csi-test.yaml"

  local ebs_pass=false
  log_info "Waiting for PVC to bind..."
  local elapsed=0
  while [ $elapsed -lt 120 ]; do
    local pvc_status
    pvc_status=$(kubectl get pvc us106-ebs-test -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
    if [ "$pvc_status" = "Bound" ]; then
      log_info "PVC is Bound (took ${elapsed}s)"
      ebs_pass=true
      break
    fi
    sleep 5
    elapsed=$((elapsed + 5))
  done

  if $ebs_pass; then
    # Verify the EBS volume was created
    local volume_id
    volume_id=$(kubectl get pv "$(kubectl get pvc us106-ebs-test -o jsonpath='{.spec.volumeName}')" \
      -o jsonpath='{.spec.csi.volumeHandle}' 2>/dev/null || echo "unknown")
    log_info "EBS Volume: ${volume_id}"

    # Check pod is running with volume
    if wait_for_pods "app=us106-ebs-writer" 1 120; then
      log_info "AC3a PASS: EBS CSI provisioned volume ${volume_id} and pod is Running"
      record_result "AC3a (EBS CSI)" "PASS" "PVC Bound, volume ${volume_id}, pod Running"
    else
      log_warn "AC3a PARTIAL: PVC Bound but pod not Running"
      record_result "AC3a (EBS CSI)" "PARTIAL" "PVC Bound but pod failed to start"
    fi
  else
    log_error "AC3a FAIL: PVC did not bind within 120s"
    kubectl describe pvc us106-ebs-test
    record_result "AC3a (EBS CSI)" "FAIL" "PVC did not bind"
  fi

  # --- LBC Test ---
  log_info "--- AC3b: AWS Load Balancer Controller ---"
  kubectl apply -f "${MANIFESTS_DIR}/04-lbc-test.yaml"

  local lbc_pass=false
  log_info "Waiting for ALB provisioning (this may take 2-3 minutes)..."
  elapsed=0
  while [ $elapsed -lt 300 ]; do
    local alb_address
    alb_address=$(kubectl get ingress us106-lbc-test \
      -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ -n "$alb_address" ]; then
      log_info "ALB provisioned: ${alb_address} (took ${elapsed}s)"
      lbc_pass=true
      break
    fi
    sleep 10
    elapsed=$((elapsed + 10))
  done

  if $lbc_pass; then
    log_info "AC3b PASS: LBC provisioned ALB at ${alb_address}"
    record_result "AC3b (LBC)" "PASS" "ALB provisioned: ${alb_address}"
  else
    log_error "AC3b FAIL: No ALB address assigned within 300s"
    kubectl describe ingress us106-lbc-test
    kubectl get events --field-selector involvedObject.name=us106-lbc-test --sort-by='.lastTimestamp' | tail -10
    record_result "AC3b (LBC)" "FAIL" "ALB not provisioned within timeout"
  fi
}

###############################################################################
# Cleanup
###############################################################################

cleanup() {
  log_info "=== Cleaning up US-106 validation resources ==="

  kubectl delete deployment us106-inflate --ignore-not-found
  kubectl delete deployment us106-spot-workload --ignore-not-found
  kubectl delete deployment us106-lbc-backend --ignore-not-found
  kubectl delete service us106-lbc-backend --ignore-not-found
  kubectl delete ingress us106-lbc-test --ignore-not-found
  kubectl delete pod us106-ebs-writer --ignore-not-found
  kubectl delete pvc us106-ebs-test --ignore-not-found
  kubectl delete nodepool us106-spot-validation --ignore-not-found

  log_info "Waiting for ALB deletion (if provisioned)..."
  sleep 30

  log_info "Cleanup complete. Auto Mode will consolidate/terminate unused nodes."
}

###############################################################################
# Main
###############################################################################

case "${1:-all}" in
  ac1)
    preflight
    test_ac1
    ;;
  ac2)
    preflight
    test_ac2
    ;;
  ac3)
    preflight
    test_ac3
    ;;
  cleanup)
    cleanup
    ;;
  all)
    preflight
    test_ac1
    echo ""
    test_ac2
    echo ""
    test_ac3
    echo ""
    log_info "=== Validation Complete ==="
    log_info "Results written to: ${RESULTS_FILE}"
    cat "${RESULTS_FILE}"
    echo ""
    log_warn "Run './validate.sh cleanup' when ready to remove test resources"
    ;;
  *)
    echo "Usage: $0 [ac1|ac2|ac3|cleanup|all]"
    exit 1
    ;;
esac

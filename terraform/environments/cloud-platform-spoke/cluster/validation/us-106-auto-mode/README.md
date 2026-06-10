# US-106: EKS Auto Mode Validation

Validation manifests and scripts for verifying EKS Auto Mode behaviour on the spoke PoC cluster.

## Prerequisites

- `kubectl` configured to access the spoke cluster
- AWS CLI configured with appropriate credentials
- Cluster is running with Auto Mode enabled (`general-purpose` + `system` node pools)

## Acceptance Criteria Mapping

| AC | Test | Script |
|----|------|--------|
| AC1 | Auto Mode provisions nodes on workload demand | `validate.sh` → Test 1 |
| AC2 | Spot diversification via NodePool | `validate.sh` → Test 2 |
| AC3 | Built-in components (LBC, EBS CSI) operational | `validate.sh` → Test 3 |

## Running

```bash
# Run all validations
./validate.sh

# Run individual tests
./validate.sh ac1   # Node provisioning
./validate.sh ac2   # Spot diversification
./validate.sh ac3   # Built-in components
```

## Clean Up

```bash
./validate.sh cleanup
```

## Expected Outcomes

- **AC1 PASS**: Nodes appear within ~90s of scaling inflate deployment; all pods reach Running
- **AC2 PASS**: Nodes show `capacity-type: spot` with multiple instance types
- **AC3 PASS**: PVC reaches Bound (EBS CSI); Ingress gets ALB address (LBC)

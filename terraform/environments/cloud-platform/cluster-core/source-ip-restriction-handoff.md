# Source-IP Restriction (Ticket 7885): Handoff

## Problem

Teams need to restrict who can reach a given route by **client source IP** (an allowlist).
On an NLB fronting Envoy, the real client IP is **not** visible by default (ip-target groups
have `preserve_client_ip` off), so Envoy sees the NLB node IP and any IP allowlist would be
meaningless. We need (a) the real client IP preserved to Envoy, and (b) a per-route,
deny-by-default allowlist that tenants manage in their own namespace.

## Solution

Two pieces, both via Envoy Gateway:

1. **Preserve client IP** at the NLB via the target-group attribute
   `preserve_client_ip.enabled=true` (set on the Envoy front-end Service in `envoy.tf`).
2. **`SecurityPolicy`** (Envoy Gateway CRD) attached to an `HTTPRoute`, `defaultAction: Deny`
   with an `Allow` rule listing permitted `clientCIDRs`.

On Auto Mode, the NLB is provisioned with `loadBalancerClass: eks.amazonaws.com/nlb` and the
cluster's **base `default-envoy-gateway`** controller (no self-managed helm install).

## Scenarios tested (all on cp-0307-1015)

| Scenario | Result |
|---|---|
| `preserve_client_ip` **OFF** | Envoy `downstream_remote_address` = `10.195.32.217` (NLB IP; client hidden), HTTP 200 |
| `preserve_client_ip` **ON** | Envoy `downstream_remote_address` = real client IP, HTTP 200 |
| Allowlist contains client IP | **HTTP 200** (curl + browser) |
| Allowlist excludes client IP (`203.0.113.0/24`) | **HTTP 403** (curl + browser) |
| Policy restored to allowed IP | **HTTP 200** |
| Tenant-namespace management | Policy in `starter-pack`, scoped to its own route |

## Verification methods

- **Envoy JSON access logs**: `kubectl logs -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-name=eg -c envoy`
  and read `downstream_remote_address` / `x-forwarded-for`.
- **AWS confirms the attribute is really applied**:
  `aws elbv2 describe-target-group-attributes --profile cp-dev --target-group-arn <tg> --query "Attributes[?Key=='preserve_client_ip.enabled']"` → `true`.
- **HTTP status** via `curl -s -o /dev/null -w '%{http_code}'` and via a browser against the
  NLB URL (`403` shows as "access denied").

## Current live state (left running, locked down)

- NLB URL: `http://k8s-envoygat-envoyenv-7fb461bfe8-ff5fdd03d11ff6f3.elb.eu-west-2.amazonaws.com/`
- Allowlist locked to **`35.176.93.186/32` (alpha VPN)** only. More IP addresses can be specified as needed in the CIDR.
- Reachable only from the alpha VPN or any other allowlisted IP address; everything else gets `403`.

## Files changed (branch `source-ip-restriction-envoy`)

- `terraform/environments/cloud-platform/cluster-core/modules/gateway_api/envoy.tf`
  - **What**: `preserve_client_ip.enabled=true` on the Envoy NLB Service (the ticket change) +
    `loadBalancerClass: eks.amazonaws.com/nlb` (Auto Mode) + explanatory comments.
  - **For**: the real client IP reaches Envoy on an Auto Mode NLB.
- `terraform/environments/cloud-platform/cluster-core/securitypolicy.yaml`
  - **What**: the deny-by-default allowlist; the allowlisted CIDR is the corporate alpha VPN.
  - **For**: the per-route source-IP restriction itself.

## Running this on an Auto Mode cluster (and why `terraform apply` alone won't work)

These changes are meant for **EKS Auto Mode clusters only**. A plain `terraform apply` of this
branch does **not** stand the stack up on Auto Mode. The gateway stack was inherited from
`cert-manager-testing` and assumes a traditional cluster, so the following blockers apply (each
is out of scope for 7885, see the next section):

- **Terraform state is unreachable** with current creds (the `modernisation-platform` state
  bucket is in another account), so the pipeline can't init the backend at all.
- The module **installs its own `helm_release.envoy_gateway`**, which duplicates/conflicts with
  the base `default-envoy-gateway` already present on Auto Mode.
- The module's Gateway expects **HTTPS + cert-manager**, which isn't installed on this cluster.
- Gatekeeper's `k8sservicetypeloadbalancer` constraint **blocks the NLB Service** until
  `envoy-gateway-system` is excluded.

How it was validated (applied by hand):

```bash
# 1. Point kubectl at the Auto Mode cluster
aws eks update-kubeconfig --name cp-0307-1015 --region eu-west-2 --profile cp-dev

# 2. Allow the Envoy LoadBalancer Service through Gatekeeper (keep deny everywhere else)
kubectl patch k8sservicetypeloadbalancer <constraint-name> --type=merge \
  -p '{"spec":{"match":{"excludedNamespaces":["envoy-gateway-system"]}}}'

# 3. Apply GatewayClass + EnvoyProxy + Gateway (the envoy.tf content, HTTP-only), binding to
#    the base controller. Do NOT install the module's envoy-gateway Helm release.
kubectl apply -f <gateway-stack>   # GatewayClass eg / EnvoyProxy custom-proxy-config / Gateway eg

# 4. Apply an HTTPRoute in the tenant namespace, then the SecurityPolicy
kubectl apply -f <httproute>       # e.g. starter-pack/hello-world
kubectl apply -f securitypolicy.yaml
```

These resources were applied by hand, so they are not in the cluster's Terraform state and will
drift on a future apply. To make it durable, resolve the items below so the branch can go
through the pipeline.

## Out of scope: needs separate ticket(s)

1. **Auto Mode compatibility of the gateway stack.** The inherited module installs its own
   `helm_release.envoy_gateway` and uses cert-manager for TLS; on Auto Mode the base cluster
   already provides envoy-gateway, so a full apply duplicates/conflicts. **Why separate**: a
   platform-migration concern (traditional to Auto Mode) larger than the source-IP feature,
   touching scaffolding not owned by 7885.
2. **Gatekeeper guardrail for the NLB Service.** We excluded `envoy-gateway-system` from the
   `k8sservicetypeloadbalancer` constraint (kept `deny` everywhere else). **Why separate**: a
   cluster-wide security decision that must be scoped/owned properly before a shared cluster.
3. **Terraform state access / drift.** The state bucket isn't reachable with current creds, so
   everything was hand-applied and sits outside Terraform state. **Why separate**: needs state
   access sorted, then the `envoy.tf` change applied via the pipeline to be durable.
4. **Multi-tenant safety (RBAC).** The mechanism is not safe multi-tenancy on its own: still
   need RBAC so a tenant can only manage policies on their own routes, plus a delivery model
   where the platform renders the SecurityPolicy from reviewed config rather than tenants
   writing raw CRDs.
5. **`aws-load-balancer-name` annotation unverified on Auto Mode.** `envoy.tf` sets a fixed NLB
   name; it wasn't used in testing (Auto Mode auto-named the NLB) and isn't in AWS's Auto Mode
   annotation list. Confirm before relying on a fixed name.
6. **Portability.** `eks.amazonaws.com/nlb` ties `envoy.tf` to Auto Mode clusters; it will not
   provision on a classic load-balancer-controller cluster.

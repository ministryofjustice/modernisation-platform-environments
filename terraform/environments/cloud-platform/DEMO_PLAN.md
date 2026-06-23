# Open-Source WAF Stack — Live Demo Plan
## Envoy Gateway + Coraza + Cert Manager vs. AWS ALB + WAF + Shield

---

## 📋 Demo Objectives

Demonstrate how a unified, open-source ingress stack (Envoy Gateway + Coraza + Cert Manager) on EKS is the **sleekest way to manage ingress across 16 clusters** while providing:
- ✅ Single Terraform module deployed to all 16 clusters (no drift)
- ✅ Superior WAF flexibility (per-route tuning, custom rules, instant updates)
- ✅ Automatic certificate management at scale (no per-cluster ACM overhead)
- ✅ Complete observability in Kubernetes (logs, metrics, RBAC, audit trail)
- ✅ No artificial limits forcing bespoke controllers (ALB's 100 TG + 25 cert limits don't apply)

---

## 🏗️ Part 1: Architecture & Setup (5 min)

**What to show:**
- Open VS Code and navigate to `cluster-core/modules/gateway_api/envoy.tf`
- Point out the single Envoy Gateway definition (just a few Terraform blocks)
- Show `cluster-core/test_workload.tf` to explain the 5 test scenarios
- Click through comparison table below

**Key message:** "One Terraform module applied to all 16 clusters. No per-cluster ALB/WAF/Shield variations. That's sleek."

### The ALB Limits Problem
```
AWS ALB: 100 target groups per ALB, 25 certs per ALB
→ With many workloads across 16 clusters, you hit both limits fast
→ Solution: Build a bespoke controller to distribute across multiple ALBs (6-9 months eng)
→ Ongoing maintenance burden

Envoy Gateway: No artificial limits
→ Single Envoy instance handles thousands of routes
→ Scale with replicas, not more gateways
→ No custom controller needed
```

### Operational Complexity Comparison

| Aspect | AWS ALB + WAF + Shield | Envoy + Coraza |
|--------|------------------------|----------------|
| **Per-cluster management** | ALB + WAF + Shield configs differ | Single unified Terraform/Helm |
| **Cert management** | Per-cluster ACM setup, manual renewal tracking | cert-manager unified across all 16 clusters |
| **WAF policies** | Per-ALB, per-region rules diverge | Single source of truth, applied everywhere |
| **WAF Updates** | AWS patches CRS with lag | Instant OWASP CRS updates, your control |
| **Rule tuning** | Must wait for AWS, support tickets | Immediate per-route override |
| **Observability** | CloudWatch + WAF Logs (separate APIs) | Unified logs/metrics, Kubernetes-native |
| **Governance** | RBAC doesn't extend to AWS WAF | Full RBAC + admission control in K8s |
| **Target groups limit** | **100 per ALB** (hard limit) | Unlimited listeners/routes per Envoy |
| **Certificate limit** | **25 certs per ALB** (hard limit) | Unlimited domains via Envoy + ListenerSets |
| **Scaling to 16 clusters** | 16× ALB management + custom controller | 1× control plane, consistent everywhere |

---

## 🔐 Part 2: Certificate Management (4 min)

**What to show:**
- Terminal: `kubectl get certificate -n envoy-gateway-system`
- Terminal: `kubectl describe cert cluster-wildcard-tls -n envoy-gateway-system`
- Point out: ACME DNS validation via Route53, auto-renewal 30 days before expiry
- Explain: "This is the same setup in all 16 clusters. No manual ACM management per cluster."

**Optional—show the ListenerSet future:**
- Sketch or point to doc: "Each team gets their own ListenerSet (separate domain + cert). Cert Manager provisions automatically per team."

---

## 🛡️ Part 3: WAF Capabilities & Tuning (10 min)

**Core concept:** Show the 5 test scenarios in `test_workload.tf` and visit each endpoint in the browser.

### 3.1 Gateway-Level Enforcement (Default Policy)
- Show: `cluster-core/modules/gateway_api/envoy.tf` → the `coraza_waf` EnvoyExtensionPolicy
- Point out: OWASP CRS included, SecRuleEngine On, JSON audit logging
- Browser: Visit `waf-inherit.cluster.example.com?id=1'+OR+'1'%3D'1` → **403 Forbidden**
- Terminal (tail logs): `kubectl logs -n envoy-gateway-system deployment/envoy` → show JSON rule fired

**Message:** "Cluster baseline. All routes inherit these protections unless explicitly tuned."

### 3.2 Detection-Only Mode (Onboarding)
- Show: `test_workload.tf` → `module.waf_detect` has `waf_rule_engine = "DetectionOnly"`
- Browser: Visit `waf-detect.cluster.example.com?id=1'+OR+'1'%3D'1` → **200 OK** (allowed, but logged)
- Show logs: Rule appears but with action=Log instead of action=Deny

**Message:** "New workloads can onboard in detection mode. Violations logged, not blocked. Flip to enforcement once tuned."

### 3.3 Full Bypass (Escape Hatch)
- Show: `test_workload.tf` → `module.waf_disabled` has `waf_rule_engine = "Off"`
- Browser: Visit `waf-disabled.cluster.example.com?id=1'+OR+'1'%3D'1` → **200 OK** (no logs)
- Show logs: No WAF entry at all for this request

**Message:** "For legacy systems, there's a governed escape hatch. Visible in audit logs, can be restricted by RBAC."

### 3.4 Per-Route Tuning (False Positive Suppression)
- Show: `test_workload.tf` → `module.waf_tuned` has `SecRuleUpdateTargetById 942100 "!ARGS:search"`
- Browser: Visit `waf-tuned.cluster.example.com?id=1'+OR+'1'%3D'1` → **403 Forbidden**
- Browser: Visit `waf-tuned.cluster.example.com?search=1'+OR+'1'%3D'1` → **200 OK**

**Message:** "Unlike AWS WAF, Coraza is surgical. Exclude specific parameters without disabling entire rules."

### 3.5 Custom Rules (Org-Specific Logic)
- Show: `test_workload.tf` → `module.waf_custom` has custom `SecRule REQUEST_URI "@beginsWith /admin" id:9001,deny`
- Browser: Visit `waf-custom.cluster.example.com` → **200 OK**
- Browser: Visit `waf-custom.cluster.example.com/admin` → **403 Forbidden** (rule 9001 fired)

**Message:** "Teams write their own rules for compliance or org logic. No waiting for AWS to add rule groups."

---

## 📊 Part 4: Observability & Logging (4 min)

**What to show:**
- Terminal: Tail Envoy logs `kubectl logs -n envoy-gateway-system deployment/envoy -f` and trigger a request
- Show JSON structure: timestamp, rule_id, action, request URI, matched args
- Explain: "All decisions are JSON, queryable by any logging backend (CloudWatch, DataDog, Splunk, etc.)"
- Terminal: `kubectl port-forward -n envoy-gateway-system svc/envoy 19000:19000`
- Browser: Open `localhost:19000` → show Envoy admin interface (stats, routing, listeners)

**Message:** "Real-time observability. You own the data. Compare to AWS WAF: logs go to S3, you poll CloudWatch, extra costs."

---

## 🚀 Part 5: Operational Efficiency & Management (3 min)

**What to show:**
- Open file explorer or VS Code: Show that all 16 clusters use the same Terraform module from this repo
- Point to `cluster-core/modules/gateway_api/` → explain: "Applied identically to each cluster."
- Draw on whiteboard or slide:
  - AWS: 16 ALBs + 16 WAF ACLs + 16 Shield configs = lots of drift risk
  - Envoy: 1 module applied to all 16 = consistency

**Key talking points:**
- "One git repo controls all 16 clusters' ingress"
- "One code review = policy applied everywhere"
- "RBAC is uniform across all clusters"
- "Cert Manager renewal is automatic and synchronized"

---

## 🔒 Part 6: Security & Governance (2 min)

**What to show:**
- Explain RBAC concept: "Only platform team can create EnvoyExtensionPolicy. App teams tune via HTTPRoute annotations only."
- Point back to test scenarios: "waf-disabled exists because governance matters. It's visible in logs, auditable, and can be blocked by admission controller if needed."
- Quick sketch: "Gatekeeper/Kyverno policies can block dangerous directives at admission layer."

**Message:** "Security enforced via Kubernetes tooling you already have. App teams get flexibility, platform team keeps control."

---

## 🎯 Part 7: Multi-Tenancy & ListenerSets (Optional, 2 min)

**What to show:**
- Sketch or whiteboard:
  - One shared Gateway per cluster
  - Multiple ListenerSets (one per team)
  - Each ListenerSet has its own domain, certificate, WAF policy
  - Scales to hundreds of domains per cluster

**Message:** "Multi-tenancy is built-in. Future-proof scaling without hitting ALB's limits."

---

## ✅ Demo Checklist

**Setup before starting:**
- [ ] VS Code open with Terraform repo
- [ ] Browser bookmarks for all 5 test domains:
  - `waf-inherit.cluster.example.com`
  - `waf-detect.cluster.example.com`
  - `waf-disabled.cluster.example.com`
  - `waf-tuned.cluster.example.com`
  - `waf-custom.cluster.example.com`
- [ ] Terminal window open to cluster directory
- [ ] Envoy logs tailing in separate terminal: `kubectl logs -n envoy-gateway-system deployment/envoy -f`

**During demo (in order):**
- [ ] **Part 1:** Show Terraform code, explain ALB limits problem
- [ ] **Part 2:** Show cert-manager resources
- [ ] **Part 3.1-3.5:** Live browser tests (5 scenarios)
- [ ] **Part 4:** Show Envoy logs and admin interface
- [ ] **Part 5:** Explain Terraform deployment model
- [ ] **Part 6:** RBAC and governance story
- [ ] **Part 7 (optional):** ListenerSet architecture

---

## 🔍 Key Talking Points

| Feature | AWS ALB + WAF | Kubernetes Envoy + Coraza | Winner |
|---------|---------|-----------------|--------|
| **Per-route tuning** | Limited (rule groups only) | Granular (per-param, per-rule) | Coraza ✅ |
| **Custom rules** | Support tickets, AWS control | Write inline SecRule, instant deploy | Coraza ✅ |
| **Consistency across 16 clusters** | Difficult (drift likely) | Unified Terraform module | Coraza ✅ |
| **Rule latency** | AWS lag for CRS updates | Instant OWASP CRS, your control | Coraza ✅ |
| **Certificate management** | Per-cluster ACM overhead | Unified cert-manager | Coraza ✅ |
| **Observability** | CloudWatch (separate API) | Kubernetes logs + Prometheus | Coraza ✅ |
| **RBAC integration** | AWS IAM only | Full Kubernetes RBAC + admission control | Coraza ✅ |
| **Hard limits (TGs, certs)** | **ALB: 100 TGs, 25 certs** → bespoke controller | **Unlimited** → no custom orchestration | Coraza ✅ |
| **Scaling to 16 clusters** | 16× ALB/WAF overhead | 1× terraform apply | Coraza ✅ |

---

## 📝 Q&A Talking Points

**Q: Consistency across 16 clusters?**
- Single Terraform module applied to each cluster via automation
- Same git repo, same review process for all WAF/cert changes
- RBAC ensures app teams can't drift policies
- Automated testing validates the config works everywhere

**Q: What about ALB's 100 target group and 25 cert limits?**
- **That's the killer problem.** Many workloads across 16 clusters = you hit both limits quickly
- AWS path: Write bespoke controller to distribute across multiple ALBs, manage cert distribution, handle rebalancing (6-9 months eng)
- Envoy path: One Envoy instance, no limits, horizontal scale with replicas. Kubernetes-native
- **Verdict:** ALB is fundamentally unmanageable without custom infrastructure

**Q: What about DDoS/Shield?**
- Envoy has rate limiting, circuit breakers, connection limits built-in
- For volumetric DDoS, CloudFront/Shield still protects at the edge
- WAF layer is now consistent and independent of managed service complexity

**Q: What if Coraza/OWASP CRS has a bypass?**
- Same risk as AWS WAF. Coraza is widely used (ModSecurity heritage, community-vetted)
- Advantage: You control the rules, patch instantly, no AWS waiting
- Disadvantage: You're responsible for staying current (not managed)

**Q: Scaling across nonprod + prod?**
- Same ingress model in all environments (consistency is the point)
- Different cert issuers per environment (staging Let's Encrypt, prod same)
- WAF policies identical; security governance enforced uniformly
- Nonprod clusters can be smaller; same operational model

**Q: Can we run both ALB + Envoy in parallel?**
- Yes. Route some traffic to ALB, some to NLB + Envoy initially
- Once confident, shift all traffic to Envoy, decommission ALB + WAF
- No hard cutover required

---

## 🚦 Success Criteria

✅ Demo lands if:
1. Audience understands the ALB limits problem (100 TGs, 25 certs) = why this is needed
2. Live browser tests show WAF flexibility (5 scenarios working as described)
3. Logging/observability story is clear (JSON to stdout, Kubernetes-native)
4. Single Terraform module across 16 clusters feels "wow, that's sleek"
5. Governance via RBAC + admission control addresses security concerns
6. ListenerSets future-proof the architecture

---

## 📚 References

- [Envoy Gateway Docs](https://gateway.envoyproxy.io/docs/)
- [Coraza / ModSecurity Docs](https://coraza.io/)
- [OWASP Core Rule Set](https://github.com/coreruleset/coreruleset)
- [cert-manager Docs](https://cert-manager.io/docs/)
- [Envoy Admin Interface](https://www.envoyproxy.io/docs/envoy/latest/operations/admin_interface)

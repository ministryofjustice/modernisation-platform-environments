# Web Application Firewall (WAF) Configuration

## Overview

The platform uses Coraza WAF with OWASP Core Rule Set (CRS) to protect applications from common web attacks. WAF protection is enabled at the Gateway level by default, and teams can customise or override this behaviour at the HTTPRoute level.

## Default Protection

All traffic through the Gateway receives OWASP CRS protection:

- **Location**: Gateway-level policy in `envoy-gateway-system` namespace
- **Mode**: Blocking (SecRuleEngine On)
- **Rules**: OWASP Core Rule Set (protects against SQL injection, XSS, command injection, etc.)
- **Applies to**: All routes through the Gateway

## Team Options

Teams can create `EnvoyExtensionPolicy` resources in their own namespaces to override the Gateway-level protection.

**⚠️ Important**: HTTPRoute-level policies **completely override** Gateway-level policies. If you create a custom policy without including OWASP CRS, you'll lose the default protection.

### Option 1: Add Custom Rules (Without OWASP CRS)

Add application-specific rules. Note this **replaces** the Gateway-level OWASP CRS protection:

```yaml
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyExtensionPolicy
metadata:
  name: my-app-custom-rules
  namespace: my-namespace
spec:
  targetRefs:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      name: my-route
  dynamicModule:
    - name: composer
      filterName: coraza-waf
      config:
        directives:
          - Include @coraza.conf
          - SecRuleEngine On
          # Add custom rules (use IDs 1000+)
          - SecRule REQUEST_HEADERS:User-Agent "@contains badbot" "id:1001,phase:1,deny,status:403,msg:'Blocked bad bot'"
```

**Use case**: Custom bot protection or IP restrictions without OWASP CRS overhead

**⚠️ Security Warning**: This disables OWASP CRS protection. Only use if you understand the security implications.

### Option 1b: Add Custom Rules With OWASP CRS

To add custom rules **whilst keeping** OWASP CRS protection, explicitly include it:

```yaml
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyExtensionPolicy
metadata:
  name: my-app-custom-plus-owasp
  namespace: my-namespace
spec:
  targetRefs:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      name: my-route
  dynamicModule:
    - name: composer
      filterName: coraza-waf
      config:
        directives:
          - Include @coraza.conf
          - SecRuleEngine On
          - Include @crs-setup.conf
          - Include @owasp_crs/*.conf
          # Add custom rules after OWASP CRS
          - SecRule REQUEST_HEADERS:User-Agent "@contains badbot" "id:1001,phase:1,deny,status:403,msg:'Blocked bad bot'"
```

**Use case**: Adding application-specific rules on top of OWASP CRS protection

### Option 2: Detection-Only Mode

Enable OWASP CRS in detection mode (logs but doesn't block) for troubleshooting false positives:

```yaml
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyExtensionPolicy
metadata:
  name: my-app-detection-mode
  namespace: my-namespace
spec:
  targetRefs:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      name: my-route
  dynamicModule:
    - name: composer
      filterName: coraza-waf
      config:
        directives:
          - Include @coraza.conf
          - SecRuleEngine DetectionOnly
          - Include @crs-setup.conf
          - Include @owasp_crs/*.conf
```

**Use case**: Investigating false positives without disrupting traffic

**Note**: In DetectionOnly mode, critical severity rules still log at `error` level, but requests are allowed through with HTTP 200 status.

### Option 3: Disable WAF

Completely disable WAF for specific routes:

```yaml
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyExtensionPolicy
metadata:
  name: my-app-waf-disabled
  namespace: my-namespace
spec:
  targetRefs:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      name: my-internal-route
  dynamicModule:
    - name: composer
      filterName: coraza-waf
      config:
        directives:
          - Include @coraza.conf
          - SecRuleEngine Off
```

**⚠️ Security Warning**: Disabling WAF removes protection from common attacks. Only use for routes that are not exposed to untrusted users.

## Common Configuration Errors

### Invalid Collection Syntax

**❌ Incorrect Example** - Using `IP` collection for variables (for demonstration only - do not use):
```yaml
# This is an EXAMPLE of incorrect syntax that will cause an error
# This will cause: "failed to compile the directive 'secaction': invalid arguments, expected collection TX"
- SecAction "id:1002,phase:1,pass,setvar:ip.requests=+1,expirevar:ip.requests=60"
- SecRule IP:REQUESTS "@gt 100" "id:1003,phase:1,deny,status:429,msg:'Rate limit exceeded'"
```

**✅ Correct** - Use `TX` (transaction) collection instead:
```yaml
# This is the correct way to implement rate limiting with custom variables
- SecAction "id:1002,phase:1,pass,setvar:TX.requests=+1,expirevar:TX.requests=60"
- SecRule TX:REQUESTS "@gt 100" "id:1003,phase:1,deny,status:429,msg:'Rate limit exceeded'"
```

### Missing Required Directives

Always include `@coraza.conf` at the start of your directives:
```yaml
directives:
  - Include @coraza.conf  # Required
  - SecRuleEngine On
  # ... other directives
```

### Forgetting to Include OWASP CRS

If you create an HTTPRoute-level policy, the Gateway-level OWASP CRS is **not** automatically applied. You must explicitly include it:
```yaml
- Include @crs-setup.conf
- Include @owasp_crs/*.conf
```

## Troubleshooting False Positives

If legitimate traffic is being blocked by OWASP CRS:

### Step 1: Identify the Rule

Check the WAF logs to find which rule is triggering:

```bash
stern . -n envoy-gateway-system | grep -i coraza
```

Look for the rule ID (e.g., `942100`) in the log entries.

### Step 2: Enable Detection-Only Mode

Create a policy with `SecRuleEngine DetectionOnly` (see Option 2 above) to allow traffic through whilst logging rule matches.

### Step 3: Create Rule Exclusions

Once you've identified the problematic rule, create a permanent policy with targeted exclusions:

```yaml
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyExtensionPolicy
metadata:
  name: my-app-rule-exclusions
  namespace: my-namespace
spec:
  targetRefs:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      name: my-route
  dynamicModule:
    - name: composer
      filterName: coraza-waf
      config:
        directives:
          - Include @coraza.conf
          - SecRuleEngine On
          - Include @crs-setup.conf
          - Include @owasp_crs/*.conf
          # Disable specific rule causing false positive
          - SecRuleRemoveById 942100
          # Or disable rule only for specific parameter
          - SecRuleUpdateTargetById 942100 "!ARGS:search_query"
```

### Step 4: Remove Detection-Only Policy

Once you've verified the exclusions work, delete the detection-only policy and keep the one with exclusions.

## Troubleshooting Policy Application

### Policy Not Taking Effect

If your HTTPRoute-level policy doesn't seem to be applying:

1. **Check policy exists:**
   ```bash
   kubectl get envoyextensionpolicy -n your-namespace
   ```

2. **Check policy status:**
   ```bash
   kubectl describe envoyextensionpolicy your-policy-name -n your-namespace
   ```

3. **Verify targetRef matches your HTTPRoute:**
   ```bash
   kubectl get httproute -n your-namespace
   ```

4. **Check for compilation errors in Envoy proxy logs:**
   ```bash
   stern . -n envoy-gateway-system | grep -i "error\|failed"
   ```

### Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `failed to compile the directive 'secaction': invalid arguments, expected collection TX` | Using `IP` collection instead of `TX` | Change `ip.varname` to `TX.varname` |
| `SecRuleEngine: Invalid value` | Typo in SecRuleEngine value | Use `On`, `Off`, or `DetectionOnly` |
| `failed to load wasm module` | Coraza filter not available | Verify Envoy Gateway has Coraza module installed |
| Policy has no status | Policy not reconciled | Check targetRef namespace and name match exactly |

## Policy Precedence

**HTTPRoute-level policies completely override Gateway-level policies:**

1. **No HTTPRoute policy** → Gateway-level policy applies (OWASP CRS enabled)
2. **HTTPRoute policy exists** → Gateway-level policy is ignored, only HTTPRoute policy applies

This means:
- If you create a custom HTTPRoute policy without OWASP CRS includes, you lose OWASP CRS protection
- To keep OWASP CRS with custom rules, explicitly include `@crs-setup.conf` and `@owasp_crs/*.conf`
- Policies do not stack or merge - it's an all-or-nothing override

## Identifying Which Policy is Active

To identify which policy is processing requests, check the EnvoyExtensionPolicy resource name in your namespace:

```bash
kubectl get envoyextensionpolicy -n your-namespace
```

You can also check the logs to see which policies are being applied to specific routes.

## Viewing WAF Logs

WAF events are logged in the Envoy proxy pods:

```bash
# View all Envoy Gateway system logs
stern . -n envoy-gateway-system

# Filter for WAF-related logs
stern . -n envoy-gateway-system | grep -i coraza

# Filter for specific policy
stern . -n envoy-gateway-system | grep "my-app-custom-rules"

# View recent errors
stern . -n envoy-gateway-system --since 5m | grep error
```

**Log levels:**
- `error` - Critical/high severity rule matches (even in DetectionOnly mode)
- `warn` - Medium severity matches
- `info` - Low severity, general operational logs

**Note**: In DetectionOnly mode, critical rules log at `error` level but requests still return HTTP 200.

## Best Practices

1. **Start with Gateway defaults** - Let OWASP CRS protect your application without custom policies
2. **Understand override behaviour** - HTTPRoute policies completely replace Gateway policies
3. **Always include OWASP CRS** - If creating a custom policy, explicitly include `@crs-setup.conf` and `@owasp_crs/*.conf` unless you have a specific reason not to
4. **Monitor logs** - Watch for legitimate traffic being blocked
5. **Use targeted exclusions** - Disable specific problematic rules, not the entire WAF
6. **Document changes** - Add comments explaining why rules are disabled or modified
7. **Use detection mode temporarily** - Don't leave applications in DetectionOnly mode permanently
8. **Test policy changes** - Use DetectionOnly mode first to verify rules work as expected
9. **Use TX collection** - For custom variables, use `TX.variable_name`, not `IP.variable_name`

## Quick Reference

### Common Directives

| Directive | Purpose | Example |
|-----------|---------|---------|
| `Include @coraza.conf` | Load base Coraza configuration | Required first directive |
| `SecRuleEngine On/Off/DetectionOnly` | Set WAF mode | `SecRuleEngine On` |
| `Include @crs-setup.conf` | Load OWASP CRS configuration | Required before CRS rules |
| `Include @owasp_crs/*.conf` | Load OWASP CRS rules | Required for CRS protection |
| `SecRuleRemoveById 942100` | Disable specific rule | For false positive fixes |
| `SecRuleUpdateTargetById 942100 "!ARGS:param"` | Exclude parameter from rule | Targeted exclusion |
| `SecRule COLLECTION:VAR "@operator value" "actions"` | Custom rule | Custom security logic |

### Custom Rule ID Ranges

| Range | Purpose |
|-------|---------|
| 1-99999 | Custom rules (recommended: 1000+) |
| 100000-199999 | Custom rules (alternative) |
| 200000-299999 | Application-specific rules |
| 900000-999999 | Reserved for OWASP CRS |

### Useful Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `@contains` | String contains | `"@contains badbot"` |
| `@rx` | Regular expression | `"@rx ^(GET\|POST)$"` |
| `@eq` | Equals | `"@eq 0"` |
| `@gt` | Greater than | `"@gt 100"` |
| `@ipMatch` | IP/CIDR match | `"@ipMatch 192.168.1.0/24"` |
| `@pm` | Pattern match (fast) | `"@pm evil bad nasty"` |

## Common OWASP CRS Rules

| Rule ID | Description | Common False Positives |
|---------|-------------|------------------------|
| 920xxx | Protocol enforcement | Large request bodies, unusual headers |
| 921xxx | Protocol attack | HTTP method restrictions |
| 930xxx | Application attack (LFI) | File path parameters |
| 931xxx | Application attack (RFI) | URL parameters |
| 932xxx | Application attack (RCE) | Code in parameters |
| 933xxx | Application attack (PHP) | PHP-like syntax in input |
| 941xxx | XSS attack | HTML/JavaScript in user content |
| 942xxx | SQL injection | SQL-like syntax in search queries |
| 943xxx | Session fixation | Session handling |

## Support

For help with WAF configuration:

1. Check logs for rule IDs and error messages
2. Review this documentation for exclusion patterns
3. Contact the platform team if you need assistance

## References

- [Coraza Documentation](https://coraza.io/)
- [OWASP Core Rule Set](https://coreruleset.org/)
- [Envoy Gateway Documentation](https://gateway.envoyproxy.io/)

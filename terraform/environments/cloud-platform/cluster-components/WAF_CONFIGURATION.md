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

Teams can create `EnvoyExtensionPolicy` resources in their own namespaces to:

1. Add custom rules on top of OWASP CRS
2. Set detection-only mode for troubleshooting
3. Disable WAF for specific routes

### Option 1: Add Custom Rules

Add application-specific rules whilst keeping OWASP CRS protection:

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
          - SecComponentSignature "my-app-custom-rules"
          # Block specific user agents
          - SecRule REQUEST_HEADERS:User-Agent "@contains badbot" "id:1001,phase:1,deny,status:403,msg:'Blocked bad bot'"
          # Rate limiting
          - SecAction "id:1002,phase:1,pass,setvar:ip.requests=+1,expirevar:ip.requests=60"
          - SecRule IP:REQUESTS "@gt 100" "id:1003,phase:1,deny,status:429,msg:'Rate limit exceeded'"
```

**Use case**: Adding bot protection, rate limiting, or application-specific security rules

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
          - SecComponentSignature "my-app-detection"
          - SecAuditEngine On
          - SecAuditLogParts ABCDEFGHIJK
          - Include @crs-setup.conf
          - Include @owasp_crs/*.conf
```

**Use case**: Investigating false positives without disrupting traffic

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
          - SecComponentSignature "my-app-waf-disabled"
```

**Use case**: Internal-only routes, legacy applications that cannot work with WAF

**⚠️ Security Warning**: Disabling WAF removes protection from common attacks. Only use for routes that are not exposed to untrusted users.

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
          - SecComponentSignature "my-app-exclusions"
          - Include @crs-setup.conf
          - Include @owasp_crs/*.conf
          # Disable specific rule causing false positive
          - SecRuleRemoveById 942100
          # Or disable rule only for specific parameter
          - SecRuleUpdateTargetById 942100 "!ARGS:search_query"
```

### Step 4: Remove Detection-Only Policy

Once you've verified the exclusions work, delete the detection-only policy and keep the one with exclusions.

## Policy Precedence

When multiple policies target the same route:

1. **Gateway-level policy** applies first (if no HTTPRoute policy exists)
2. **HTTPRoute-level policy** overrides Gateway-level (when attached to the same route)
3. Multiple directives are processed in order

## Identifying Which Policy is Active

Each policy has a `SecComponentSignature` directive that appears in logs. Use this to identify which policy is processing requests:

- `default-coraza-waf` - Gateway-level policy
- `my-app-*` - Team-specific policies (use descriptive names)

## Best Practices

1. **Start with Gateway defaults** - Let OWASP CRS protect your application
2. **Monitor logs** - Watch for legitimate traffic being blocked
3. **Use targeted exclusions** - Only disable specific rules, not the entire WAF
4. **Document changes** - Add comments explaining why rules are disabled
5. **Review regularly** - Periodically check if exclusions are still needed
6. **Use detection mode temporarily** - Don't leave applications in detection-only mode permanently

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

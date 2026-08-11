# Gateway-level WAF policy with OWASP CRS
# This applies to ALL routes through the Gateway by default
# Teams can override this at the HTTPRoute level if needed
resource "kubernetes_manifest" "default-coraza-waf" {
  manifest = yamldecode(<<-YAML
    apiVersion: gateway.envoyproxy.io/v1alpha1
    kind: EnvoyExtensionPolicy
    metadata:
      name: default-coraza-waf
      namespace: envoy-gateway-system
    spec:
      targetRefs:
        - group: gateway.networking.k8s.io
          kind: Gateway
          name: default
          namespace: envoy-gateway-system
      dynamicModule:
        - name: composer
          filterName: coraza-waf
          config:
            directives:
              - Include @coraza.conf
              - SecRuleEngine On
              - Include @crs-setup.conf
              - Include @owasp_crs/*.conf        
  YAML
  )
}

# # Example 1: Team deploys a httproute without EnvoyExtensionPolicy, so the Gateway-level OWASP CRS protection applies

# Example 2: Team adds custom rules WITHOUT OWASP CRS
# HTTPRoute-level policy overrides Gateway-level, so this route only has custom rules
resource "kubernetes_manifest" "starter-pack-coraza-waf-with-custom-rules" {
  manifest = yamldecode(<<-YAML
    apiVersion: gateway.envoyproxy.io/v1alpha1
    kind: EnvoyExtensionPolicy
    metadata:
      name: starter-pack-coraza-waf-with-custom-rules
      namespace: starter-pack-2
    spec:
      targetRefs:
        - group: gateway.networking.k8s.io
          kind: HTTPRoute
          name: starter-pack-route
          namespace: starter-pack-2
      dynamicModule:
        - name: composer
          filterName: coraza-waf
          config:
            directives:
              - Include @coraza.conf
              - SecRuleEngine On
              # Add custom rules specific to this application (use IDs 1000+)
              - SecRule REQUEST_HEADERS:User-Agent "@contains badbot" "id:1001,phase:1,deny,status:403,msg:'Blocked bad bot'"
              ## SecRule REMOTE_ADDR "@ipMatch 86.136.25.232/32" "id:1002,phase:1,deny,status:403,log,msg:'source IP not allowed'"
  YAML
  )
}

# Example 3: Team disables OWASP CRS for troubleshooting false positives
# Sets DetectionOnly mode to log without blocking
resource "kubernetes_manifest" "starter-pack-coraza-waf-detection" {
  manifest = yamldecode(<<-YAML
    apiVersion: gateway.envoyproxy.io/v1alpha1
    kind: EnvoyExtensionPolicy
    metadata:
      name: starter-pack-coraza-waf-detection
      namespace: starter-pack-3
    spec:
      targetRefs:
        - group: gateway.networking.k8s.io
          kind: HTTPRoute
          name: starter-pack-route
          namespace: starter-pack-3
      dynamicModule:
        - name: composer
          filterName: coraza-waf
          config:
            directives:
              - Include @coraza.conf
              - SecRuleEngine DetectionOnly
              - Include @crs-setup.conf
              - Include @owasp_crs/*.conf
  YAML
  )
}

# Example 4: Team completely disables WAF for specific route
# Use with caution - no protection for this route
resource "kubernetes_manifest" "starter-pack-coraza-waf-off" {
  manifest = yamldecode(<<-YAML
    apiVersion: gateway.envoyproxy.io/v1alpha1
    kind: EnvoyExtensionPolicy
    metadata:
      name: starter-pack-coraza-waf-off
      namespace: starter-pack-4
    spec:
      targetRefs:
        - group: gateway.networking.k8s.io
          kind: HTTPRoute
          name: starter-pack-route
          namespace: starter-pack-4
      dynamicModule:
        - name: composer
          filterName: coraza-waf
          config:
            directives:
              - Include @coraza.conf
              - SecRuleEngine Off
  YAML
  )
}

# Example 5: Invalid configuration that will cause compilation errors
# This demonstrates what happens when using incorrect SecAction/SecRule syntax
resource "kubernetes_manifest" "starter-pack-coraza-waf-invalid" {
  manifest = yamldecode(<<-YAML
    apiVersion: gateway.envoyproxy.io/v1alpha1
    kind: EnvoyExtensionPolicy
    metadata:
      name: starter-pack-coraza-waf-invalid
      namespace: starter-pack-5
    spec:
      targetRefs:
        - group: gateway.networking.k8s.io
          kind: HTTPRoute
          name: starter-pack-route
          namespace: starter-pack-5
      dynamicModule:
        - name: composer
          filterName: coraza-waf
          config:
            directives:
              - Include @coraza.conf
              - SecRuleEngine On
              # INVALID: Using IP collection instead of TX collection
              - SecAction "id:1002,phase:1,pass,setvar:ip.requests=+1,expirevar:ip.requests=60"
  YAML
  )
}

# Example 6: Team adds custom rules WITHOUT OWASP CRS, after bad configuration previously caused compilation errors
resource "kubernetes_manifest" "starter-pack-coraza-waf-with-custom-rules_after_bad_config" {
  manifest = yamldecode(<<-YAML
    apiVersion: gateway.envoyproxy.io/v1alpha1
    kind: EnvoyExtensionPolicy
    metadata:
      name: starter-pack-coraza-waf-with-custom-rules-after-bad-config
      namespace: starter-pack-6
    spec:
      targetRefs:
        - group: gateway.networking.k8s.io
          kind: HTTPRoute
          name: starter-pack-route
          namespace: starter-pack-6
      dynamicModule:
        - name: composer
          filterName: coraza-waf
          config:
            directives:
              - Include @coraza.conf
              - SecRuleEngine On
              # Add custom rules specific to this application (use IDs 1000+)
              - SecRule REMOTE_ADDR "@ipMatch 86.136.25.232/32" "id:1001,phase:1,deny,status:403,log,msg:'source IP not allowed'"
  YAML
  )
}
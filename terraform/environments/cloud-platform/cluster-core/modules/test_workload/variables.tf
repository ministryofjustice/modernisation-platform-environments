variable "name" {
  type        = string
  description = "Unique name for this test workload. Used as namespace, deployment, service and HTTPRoute name."
}

variable "hostname" {
  type        = string
  description = "Hostname for the HTTPRoute (DNS name only, no https:// scheme)."
}

variable "gateway_name" {
  type        = string
  default     = "eg"
  description = "Name of the parent Gateway resource."
}

variable "gateway_namespace" {
  type        = string
  default     = "envoy-gateway-system"
  description = "Namespace of the parent Gateway resource."
}

# ---------------------------------------------------------------------------
# WAF policy controls
# ---------------------------------------------------------------------------

variable "create_waf_policy" {
  type    = bool
  default = true
  description = <<-EOT
    Whether to create a route-level EnvoyExtensionPolicy for this workload.
    Set to false to rely entirely on the cluster-wide Gateway-level policy
    (useful for demonstrating inherited detection-only behaviour).
  EOT
}

variable "waf_rule_engine" {
  type    = string
  default = "DetectionOnly"
  description = <<-EOT
    Coraza SecRuleEngine value for the route-level policy.
      On            – enforce: block requests that match rules (returns 403).
      DetectionOnly – log only: never block, useful for shadow mode / tuning.
      Off           – disable WAF for this route entirely (escape hatch).
  EOT

  validation {
    condition     = contains(["On", "DetectionOnly", "Off"], var.waf_rule_engine)
    error_message = "waf_rule_engine must be On, DetectionOnly, or Off."
  }
}

variable "extra_waf_directives" {
  type    = list(string)
  default = []
  description = <<-EOT
    Additional Coraza directives appended after the OWASP CRS includes.
    Applied after all base directives so they can override or extend CRS behaviour.

    Examples:
      # Disable a specific rule globally for this route (known false-positive):
      "SecRuleRemoveById 942100"

      # Disable a rule only for a specific argument:
      "SecRuleUpdateTargetById 942200 \"!ARGS:search\""

      # Add a custom blocking rule:
      "SecRule REQUEST_URI \"@contains /admin\" \"id:9001,phase:1,deny,status:403,msg:'Admin path blocked'\""

      # Tune anomaly score threshold:
      "SecAction \"id:900110,phase:1,pass,nolog,setvar:tx.inbound_anomaly_score_threshold=10\""
  EOT
}

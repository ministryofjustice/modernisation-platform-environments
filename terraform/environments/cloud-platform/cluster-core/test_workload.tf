# WAF demo workloads.
#
# ┌──────────────┬───────────────────────────────────────────────────────────┐
# │ Module       │ What it demonstrates                                      │
# ├──────────────┼───────────────────────────────────────────────────────────┤
# │ waf_inherit  │ No route policy – cluster enforcement applies automatically │
# │ waf_detect   │ Override to DetectionOnly – logs only, never blocks        │
# │ waf_disabled │ SecRuleEngine Off – full escape hatch from cluster WAF     │
# │ waf_tuned    │ Enforce + targeted rule exclusion for a false positive     │
# │ waf_custom   │ Enforce + a bespoke SecRule not in OWASP CRS               │
# └──────────────┴───────────────────────────────────────────────────────────┘

locals {
  waf_inherit_hostname  = format("%s.%s.%s", "waf-inherit", local.cluster_name, local.cluster_base_domain)
  waf_detect_hostname   = format("%s.%s.%s", "waf-detect", local.cluster_name, local.cluster_base_domain)
  waf_disabled_hostname = format("%s.%s.%s", "waf-disabled", local.cluster_name, local.cluster_base_domain)
  waf_tuned_hostname    = format("%s.%s.%s", "waf-tuned", local.cluster_name, local.cluster_base_domain)
  waf_custom_hostname   = format("%s.%s.%s", "waf-custom", local.cluster_name, local.cluster_base_domain)
  waf_new_hostname      = format("%s.%s.%s", "waf-new", local.cluster_name, local.cluster_base_domain)
}
# waf_inherit:
#   curl "https://${local.waf_inherit_hostname}/?id=1'+OR+'1'%3D'1" -v
#     → 403 Forbidden (blocked by cluster-wide enforcement, no override)

module "waf_inherit" {
  source = "./modules/test_workload"

  name     = "waf-inherit"
  hostname = local.waf_inherit_hostname

  # No route-level EEP created at all. Demonstrates the cluster-wide baseline:
  # every route is automatically protected by cluster enforcement unless explicitly overridden.
  create_waf_policy = false

  depends_on = [module.gateway_api]
}

# waf_detect:
#   curl "https://${local.waf_detect_hostname}/?id=1'+OR+'1'%3D'1" -v
#     → 200 OK (SQL injection logged, not blocked)

module "waf_detect" {
  source = "./modules/test_workload"

  name     = "waf-detect"
  hostname = local.waf_detect_hostname

  # Override cluster enforcement – useful while onboarding or tuning rules.
  waf_rule_engine = "DetectionOnly"

  depends_on = [module.gateway_api]
}

# waf_disabled:
#   curl "https://${local.waf_disabled_hostname}/?id=1'+OR+'1'%3D'1" -v
#     → 200 OK (route-level WAF off, but Gateway still detects & logs)

module "waf_disabled" {
  source = "./modules/test_workload"

  name     = "waf-disabled"
  hostname = local.waf_disabled_hostname

  # WAF inspection fully disabled for this route – escape hatch for services
  # that cannot tolerate cluster enforcement. Demonstrates teams can opt-out if needed.
  waf_rule_engine = "Off"

  depends_on = [module.gateway_api]
}

# waf_tuned:
#   curl "https://${local.waf_tuned_hostname}/?id=1'+OR+'1'%3D'1" -v
#     → 403 Forbidden (SQL injection blocked on id param)
#   curl "https://${local.waf_tuned_hostname}/?search=1'+OR+'1'%3D'1" -v
#     → 200 OK (SQL injection allowed on search param via SecRuleUpdateTargetById)

module "waf_tuned" {
  source = "./modules/test_workload"

  name     = "waf-tuned"
  hostname = local.waf_tuned_hostname

  # Enforce mode with a targeted exclusion for a known false positive:
  # rule 942100 (SQL injection via libinjection) is disabled only for the
  # 'search' parameter, leaving all other args fully inspected and blocked.
  waf_rule_engine = "On"

  extra_waf_directives = [
    "SecRuleUpdateTargetById 942100 \"!ARGS:search\"",
  ]

  depends_on = [module.gateway_api]
}

# waf_custom:
#   curl "https://${local.waf_custom_hostname}/" -v
#     → 200 OK (clean request)
#   curl "https://${local.waf_custom_hostname}/admin" -v
#     → 403 Forbidden (custom rule blocks /admin path)

module "waf_custom" {
  source = "./modules/test_workload"

  name     = "waf-custom"
  hostname = local.waf_custom_hostname

  # Enforce mode with a bespoke team rule appended after the CRS includes.
  # Demonstrates that teams can add custom logic without modifying the CRS.
  waf_rule_engine = "On"

  extra_waf_directives = [
    "SecRule REQUEST_URI \"@beginsWith /admin\" \"id:9001,phase:1,deny,status:403,msg:'Admin path blocked by custom rule'\"",
  ]

  depends_on = [module.gateway_api]
}

module "waf_new" {
  source = "./modules/test_workload"

  name     = "waf-new"
  hostname = local.waf_new_hostname

  # Enforce mode with a bespoke team rule appended after the CRS includes.
  # Demonstrates that teams can add custom logic without modifying the CRS.
  waf_rule_engine = "On"

  extra_waf_directives = [
    "SecRule REQUEST_URI \"@beginsWith /admin\" \"id:9001,phase:1,deny,status:403,msg:'Admin path blocked by custom rule'\"",
  ]

  depends_on = [module.gateway_api]
}


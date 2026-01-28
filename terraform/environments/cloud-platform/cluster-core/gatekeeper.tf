module "gatekeeper" {
  count  = contains(local.enabled_workspaces, local.cluster_environment) ? 1 : 0
  source = "github.com/ministryofjustice/cloud-platform-terraform-gatekeeper?ref=cp30-baseline"

  # boolean expression for applying opa valid hostname for test clusters only.
  dryrun_map = {
    service_type                       = false,
    warn_service_account_secret_delete = false,
    user_ns_requires_psa_label         = false,
    lock_priv_capabilities             = false,
    warn_kubectl_create_sa             = false,
  }

  constraint_violations_max_to_display = 25
  is_production                        = contains(local.mp_environments, terraform.workspace) ? "true" : "false"
  environment_name                     = terraform.workspace
  out_of_hours_alert                   = "false"
  controller_mem_limit                 = "1Gi"
  controller_mem_req                   = "512Mi"
  audit_mem_limit                      = "1Gi"
  audit_mem_req                        = "512Mi"
}

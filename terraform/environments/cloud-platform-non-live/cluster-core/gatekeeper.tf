module "gatekeeper" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-gatekeeper?ref=cp30-baseline"

  # boolean expression for applying opa valid hostname for test clusters only.
  dryrun_map = {
    service_type                       = true,
    warn_service_account_secret_delete = true,
    user_ns_requires_psa_label         = true,
    lock_priv_capabilities             = true,
    warn_kubectl_create_sa             = true,
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
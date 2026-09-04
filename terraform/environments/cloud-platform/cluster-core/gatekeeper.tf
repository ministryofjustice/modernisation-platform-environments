module "gatekeeper" {
  source = "github.com/ministryofjustice/container-platform-terraform-gatekeeper?ref=1e282d05902b17fa31f00e152aade64d86e7d181" #1.3.0

  # boolean expression for applying opa valid hostname for test clusters only.
  dryrun_map = {
    service_type                       = false,
    warn_service_account_secret_delete = false,
    user_ns_requires_psa_label         = false,
    lock_priv_capabilities             = false,
    warn_kubectl_create_sa             = false,
    # TEMPORARY (observability PoC, issue 8414): dryrun instead of deny so the
    # amazon-cloudwatch-observability add-on's cloudwatch-agent DaemonSet
    # (hostNetwork: true) can schedule. Revert to false once the gatekeeper
    # module exempts amazon-cloudwatch from the disallow-host-network constraint.
    block_host_network = true,
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

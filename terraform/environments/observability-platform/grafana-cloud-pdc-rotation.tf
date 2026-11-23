locals {
  pdc_rotation_interval_days = 90
  pdc_token_grace_days       = 7

  # Use these rules when the tested rotation Lambda is available. Do not enable rotation yet.
  pdc_rotation_rules = {
    automatically_after_days = local.pdc_rotation_interval_days
  }

  pdc_token_lifetime_days = local.pdc_rotation_interval_days + local.pdc_token_grace_days

  gc_pdc_rotator_role_name = "grafana-pdc-token-rotator"
  gc_pdc_restarter_role_arns = {
    for account_name, account_id in local.gc_pdc_accounts :
    account_name => "arn:aws:iam::${account_id}:role/grafana-pdc-agent-restarter"
  }

  gc_pdc_rotation_tags = {
    for account_name, account_id in local.gc_pdc_accounts : account_name => {
      "pdc:tenant-account-id" = account_id
      "pdc:access-policy-id"  = grafana_cloud_private_data_source_connect_network.account[account_name].pdc_network_id
      "pdc:region"            = grafana_cloud_private_data_source_connect_network.account[account_name].region
      "pdc:stack-id"          = grafana_cloud_stack.observability_platform.id
      "pdc:token-ttl-seconds" = tostring(local.pdc_token_lifetime_days * 24 * 60 * 60)
      "pdc:ecs-region"        = data.aws_region.current.name
      "pdc:ecs-cluster"       = "grafana-pdc-agent"
      "pdc:ecs-service"       = "grafana-pdc-agent"
    }
  }
}

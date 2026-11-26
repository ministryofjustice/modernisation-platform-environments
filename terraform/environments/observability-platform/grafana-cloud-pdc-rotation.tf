locals {
  pdc_rotation_interval_days = 90
  pdc_token_grace_days       = 7

  # These accounts already have working tokens. Never send either through first issuance.
  gc_pdc_seeded_accounts = local.environment == "development" ? toset(["sprinkler-development", "cooker-development"]) : toset([])
  gc_pdc_bootstrap_accounts = {
    for account_name, account_id in local.gc_pdc_accounts :
    account_name => account_id if !contains(local.gc_pdc_seeded_accounts, account_name)
  }

  # Terraform-owned schedules: the seeded accounts, once the rotator is deployed.
  gc_pdc_rotation_accounts = {
    for account_name, account_id in local.gc_pdc_accounts :
    account_name => account_id
    if contains(local.gc_pdc_seeded_accounts, account_name) && local.environment_configuration_gc.pdc_token_rotator != null
  }

  # The reconciler, not Terraform, owns these native rotation schedules once the agents connect.
  gc_pdc_enrolment_accounts = {
    for name, id in local.gc_pdc_bootstrap_accounts : name => id
    if try(local.environment_configuration_gc.pdc_token_rotator.bootstrap_enabled, false)
  }

  pdc_rotation_rules = {
    automatically_after_days = local.pdc_rotation_interval_days
  }

  pdc_token_lifetime_days = local.pdc_rotation_interval_days + local.pdc_token_grace_days

  gc_pdc_rotator_role_name = "grafana-pdc-token-rotator"
  gc_pdc_restarter_role_arns = {
    for account_name, account_id in merge(local.gc_pdc_rotation_accounts, local.gc_pdc_enrolment_accounts) :
    account_name => "arn:aws:iam::${account_id}:role/grafana-pdc-agent-restarter"
  }

  gc_pdc_rotation_tags = {
    for account_name, account_id in local.gc_pdc_accounts : account_name => merge(
      {
        "pdc:tenant-account-id" = account_id
        "pdc:access-policy-id"  = grafana_cloud_private_data_source_connect_network.account[account_name].pdc_network_id
        "pdc:region"            = grafana_cloud_private_data_source_connect_network.account[account_name].region
        "pdc:stack-id"          = grafana_cloud_stack.observability_platform.id
        "pdc:token-ttl-seconds" = tostring(local.pdc_token_lifetime_days * 24 * 60 * 60)
        "pdc:ecs-region"        = data.aws_region.current.name
        "pdc:ecs-cluster"       = "grafana-pdc-agent"
        "pdc:ecs-service"       = "grafana-pdc-agent"
      },
      contains(keys(local.gc_pdc_bootstrap_accounts), account_name) ? {
        "pdc:bootstrap"              = "true"
        "pdc:rotation-interval-days" = tostring(local.pdc_rotation_interval_days)
      } : {}
    )
  }
}

resource "aws_secretsmanager_secret_rotation" "gc_pdc_token" {
  for_each = local.gc_pdc_rotation_accounts

  secret_id           = aws_secretsmanager_secret.gc_pdc_token[each.key].id
  rotation_lambda_arn = module.grafana_pdc_token_rotator["this"].lambda_function_arn
  rotate_immediately  = true

  rotation_rules {
    automatically_after_days = local.pdc_rotation_rules.automatically_after_days
  }

  depends_on = [module.grafana_pdc_token_rotator]
}

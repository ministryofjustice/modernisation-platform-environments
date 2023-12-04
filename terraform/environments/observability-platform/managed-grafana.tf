module "managed_grafana" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/managed-service-grafana/aws"
  version = "~> 2.0"

  name = local.application_name

  license_type = "ENTERPRISE"

  account_access_type       = "CURRENT_ACCOUNT"
  authentication_providers  = ["AWS_SSO"]
  permission_type           = "SERVICE_MANAGED"
  data_sources              = ["CLOUDWATCH", "PROMETHEUS"]
  notification_destinations = ["SNS"]

  iam_role_policy_arns = [module.amazon_managed_grafana_remote_cloudwatch_iam_policy.arn]

  configuration = jsonencode({
    unifiedAlerting = {
      enabled = true
    }
    plugins = {
      pluginAdminEnabled = true
    }
  })

  role_associations = {
    "ADMIN" = {
      "group_ids" = ["16a2d234-1031-70b5-2657-7f744c55e48f"] # observability-platform
    }
  }

  tags = local.tags
}

locals {
  grafana_api_key_expiration_days    = 30
  grafana_api_key_expiration_seconds = 60 * 60 * 24 * local.grafana_api_key_expiration_days
}

resource "time_rotating" "grafana_api_key_rotation" {
  rotation_days = local.grafana_api_key_expiration_days
}

resource "time_static" "grafana_api_key_rotation" {
  rfc3339 = time_rotating.grafana_api_key_rotation.rfc3339
}

resource "aws_grafana_workspace_api_key" "automation_key" {
  workspace_id = module.managed_grafana.workspace_id

  key_name        = "automation"
  key_role        = "ADMIN"
  seconds_to_live = local.grafana_api_key_expiration_seconds

  lifecycle {
    replace_triggered_by = [time_static.grafana_api_key_rotation]
  }
}

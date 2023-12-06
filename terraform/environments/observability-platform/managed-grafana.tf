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
    "EDITOR" = {
      "group_ids" = local.all_sso_uuids
    }
  }

  tags = local.tags
}

/* Grafana API */
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

/* Prometheus Source */
resource "grafana_data_source" "observability_platform_prometheus" {
  type       = "prometheus"
  name       = "observability-platform-prometheus"
  url        = module.managed_prometheus.workspace_prometheus_endpoint
  is_default = true
  json_data_encoded = jsonencode({
    httpMethod    = "POST"
    sigV4Auth     = true
    sigV4AuthType = "ec2_iam_role"
    sigV4Region   = "eu-west-2"
  })
}

/* CloudWatch Sources */
module "cloudwatch_sources" {
  for_each = {
    for account in local.all_cloudwatch_accounts : account => {
      account_id = account
    }
  }

  source = "./modules/grafana/cloudwatch-source"

  name       = each.key
  account_id = local.environment_management.account_ids[each.key]
}

/* Tenant RBAC */
module "tenant_rbac" {
  for_each = local.environment_configuration.observability_platform_configuration

  source = "./modules/grafana/tenant-rbac"

  name                = each.key
  sso_uuid            = each.value.sso_uuid
  cloudwatch_accounts = each.value.cloudwatch_accounts

  depends_on = [module.cloudwatch_sources]
}

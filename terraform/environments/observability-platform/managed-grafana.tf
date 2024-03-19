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
      "group_ids" = [data.aws_identitystore_group.observability_platform.id]
    }
    "EDITOR" = {
      "group_ids" = [for team in data.aws_identitystore_group.all_identity_centre_teams : team.id]
    }
  }

  tags = local.tags
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

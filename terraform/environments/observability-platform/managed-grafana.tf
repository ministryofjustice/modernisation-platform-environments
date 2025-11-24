#tfsec:ignore:avd-aws-0057 Wildcard statements come from module's data.aws_iam_policy_document
module "managed_grafana" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  #checkov:skip=CKV2_AWS_5:AMG doesn't run in a VPC, so it doesn't need a security group

  source  = "terraform-aws-modules/managed-service-grafana/aws"
  version = "2.2.0"

  name = local.application_name

  license_type    = "ENTERPRISE"
  grafana_version = local.environment_configuration.grafana_version

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
      "group_ids" = [for group in data.aws_identitystore_group.observability_platform_admins : group.id]
    }
    "EDITOR" = {
      "group_ids" = [for team in data.aws_identitystore_group.all_identity_centre_teams : team.id]
    }
  }

  tags = local.tags
}

resource "aws_grafana_workspace_service_account" "automation" {
  name         = "automation"
  grafana_role = "ADMIN"
  workspace_id = module.managed_grafana.workspace_id
}

/* Slack Contact Points */
module "contact_point_slack" {
  for_each = toset(local.all_slack_channels)

  source = "./modules/grafana/contact-point/slack"

  channel = each.value
}

/* PagerDuty Contact Points */
module "contact_point_pagerduty" {
  for_each = toset(local.all_pagerduty_services)

  source = "./modules/grafana/contact-point/pagerduty"

  service = each.value
}

/* Notification Policy */
resource "grafana_notification_policy" "root" {
  contact_point   = "grafana-default-sns"
  group_by        = ["..."]
  group_wait      = "30s"
  group_interval  = "5m"
  repeat_interval = "4h"

  dynamic "policy" {
    for_each = toset(local.all_slack_channels)
    content {
      matcher {
        label = "slack-channel"
        match = "="
        value = policy.value
      }
      contact_point = "${policy.value}-slack"
    }
  }

  dynamic "policy" {
    for_each = toset(local.all_pagerduty_services)
    content {
      matcher {
        label = "pagerduty-integration"
        match = "="
        value = policy.value
      }
      contact_point = "${policy.value}-pagerduty"
    }
  }

  depends_on = [
    module.contact_point_slack,
    module.contact_point_pagerduty
  ]
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

/* GitHub Source */
resource "grafana_data_source" "github" {
  type = "grafana-github-datasource"
  name = "ministryofjustice-github"
  url  = module.managed_prometheus.workspace_prometheus_endpoint
  json_data_encoded = jsonencode({
    owner = "ministryofjustice"
  })
  secure_json_data_encoded = jsonencode({
    appId          = data.aws_secretsmanager_secret_version.github_app_id.secret_string
    installationId = data.aws_secretsmanager_secret_version.github_app_installation_id.secret_string
    privateKey     = data.aws_secretsmanager_secret_version.github_app_private_key.secret_string
  })
}

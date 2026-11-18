# Data sources in this environment's Grafana Cloud stack. Tenants and their AWS accounts are configured in
# grafana-cloud-tenant-environment-configurations.tf.

# The GitHub data source plugin isn't installed in Grafana Cloud stacks by default.
resource "grafana_cloud_plugin_installation" "github" {
  provider = grafana.cloud

  stack_slug = grafana_cloud_stack.observability_platform.slug
  slug       = "grafana-github-datasource"
  version    = "2.10.0"
}

# Uses the same GitHub App as the Amazon Managed Grafana data source in managed-grafana.tf.
resource "grafana_data_source" "cloud_github" {
  provider = grafana.stack

  type = "grafana-github-datasource"
  name = "ministryofjustice-github"
  json_data_encoded = jsonencode({
    owner            = "ministryofjustice"
    selectedAuthType = "github-app"
    appId            = data.aws_secretsmanager_secret_version.github_app_id.secret_string
    installationId   = data.aws_secretsmanager_secret_version.github_app_installation_id.secret_string
  })
  secure_json_data_encoded = jsonencode({
    privateKey = data.aws_secretsmanager_secret_version.github_app_private_key.secret_string
  })

  depends_on = [grafana_cloud_plugin_installation.github]
}

locals {
  # IAM role created in each tenant account by the tenant module
  # (ministryofjustice/terraform-aws-observability-platform-tenant). Grafana Cloud's AWS account
  # assumes it with the stack ID as the external ID.
  gc_aws_role_name = "grafana-cloud"

  # Plugins for the AWS data sources, installed only when an account in this environment uses them.
  # CloudWatch is a core data source.
  gc_aws_plugins = {
    "grafana-x-ray-datasource" = {
      version = "2.17.7"
      used    = anytrue([for account in values(local.gc_accounts) : account.xray.enabled])
    }
    "grafana-amazonprometheus-datasource" = {
      version = "3.3.5"
      used    = anytrue([for account in values(local.gc_accounts) : account.amazon_prometheus != null])
    }
  }
}

resource "grafana_cloud_plugin_installation" "aws" {
  for_each = { for slug, plugin in local.gc_aws_plugins : slug => plugin.version if plugin.used }
  provider = grafana.cloud

  stack_slug = grafana_cloud_stack.observability_platform.slug
  slug       = each.key
  version    = each.value
}

# CloudWatch, X-Ray and Amazon Managed Service for Prometheus data sources for each tenant account,
# named "<account>-cloudwatch", "<account>-xray" and "<account>-amp". Keyed by account, so moving
# an account to another tenant only changes who can query its data sources.
module "grafana_cloud_aws_data_sources" {
  for_each = local.gc_accounts
  source   = "./modules/grafana-cloud/aws-account-data-sources"

  providers = {
    grafana = grafana.stack
  }

  name              = each.key
  role_arn          = "arn:aws:iam::${local.all_account_ids[each.key]}:role/${local.gc_aws_role_name}"
  cloudwatch        = each.value.cloudwatch
  xray              = each.value.xray
  amazon_prometheus = each.value.amazon_prometheus
  # The teams of the owning tenant and the tenants the account is shared with. Only tenants with a
  # GitHub team have a Grafana team.
  query_team_ids = [
    for tenant in each.value.query_tenants : module.grafana_cloud_team[tenant].team_id
    if contains(keys(module.grafana_cloud_team), tenant)
  ]

  depends_on = [grafana_cloud_plugin_installation.aws]
}

# Data sources in this environment's Grafana Cloud stack.

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

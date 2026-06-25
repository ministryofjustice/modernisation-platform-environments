# Kubernetes provider for managing resources in the Cloud Platform cluster
provider "kubernetes" {
  host                   = try(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["cluster_endpoint"], null)
  cluster_ca_certificate = try(base64decode(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["ca_certificate"]), null)
  token                  = try(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["token"], null)
}

# Helm provider for deploying charts to the Cloud Platform cluster
provider "helm" {
  kubernetes = {
    host                   = try(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["cluster_endpoint"], null)
    cluster_ca_certificate = try(base64decode(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live[0].secret_string)["ca_certificate"]), null)
    token                  = try(jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["token"], null)
  }
}

# Grafana provider for managing dashboards and folders as code. Grafana is
# pure-SSO, so it authenticates with a service-account token read from Secrets
# Manager (secrets.tf/data.tf). Where the monitoring stack is disabled, or before
# the token is populated, there are no grafana resources, so the URL and token
# below are never used to open a connection.
provider "grafana" {
  url  = "https://${try(local.environment_configuration.monitoring_hostname, "grafana.invalid")}"
  auth = coalesce(local.grafana_api_token, "placeholder")
}

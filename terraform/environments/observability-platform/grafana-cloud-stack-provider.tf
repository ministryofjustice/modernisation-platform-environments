# Service account and provider for managing resources inside this environment's Grafana Cloud stack
# (data sources, plugins, folders, dashboards). The grafana.cloud provider only manages Cloud
# account resources such as stacks and access policies.

resource "grafana_cloud_stack_service_account" "terraform" {
  provider = grafana.cloud

  stack_slug  = grafana_cloud_stack.observability_platform.slug
  name        = "terraform"
  role        = "Admin"
  is_disabled = false
}

resource "grafana_cloud_stack_service_account_token" "terraform" {
  provider = grafana.cloud

  stack_slug         = grafana_cloud_stack.observability_platform.slug
  service_account_id = grafana_cloud_stack_service_account.terraform.id
  name               = "terraform"
}

provider "grafana" {
  alias = "stack"
  url   = grafana_cloud_stack.observability_platform.url
  auth  = grafana_cloud_stack_service_account_token.terraform.key
}

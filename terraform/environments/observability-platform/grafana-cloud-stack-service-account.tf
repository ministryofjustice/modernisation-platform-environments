# Service account used by the grafana.stack provider (providers.tf) to manage resources inside this
# environment's Grafana Cloud stack (data sources, folders, dashboards). The grafana.cloud provider
# only manages Cloud account resources such as stacks, plugins and access policies.

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

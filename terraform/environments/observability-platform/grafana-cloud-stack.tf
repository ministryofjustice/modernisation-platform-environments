resource "grafana_cloud_stack" "observability_platform" {
  provider = grafana.cloud

  name        = "mojobservability${local.environment}"
  slug        = "mojobservability${local.environment}"
  region_slug = "prod-gb-south-1"
  description = "Modernisation Platform observability - ${local.environment}"

  labels = {
    environment = local.environment
    application = local.application_name
  }

  lifecycle {
    prevent_destroy = true
  }
}

output "grafana_cloud_stack" {
  description = "Grafana Cloud stack managed by this environment's Terraform workspace."
  value = {
    id          = grafana_cloud_stack.observability_platform.id
    slug        = grafana_cloud_stack.observability_platform.slug
    url         = grafana_cloud_stack.observability_platform.url
    region_slug = grafana_cloud_stack.observability_platform.region_slug
  }
}

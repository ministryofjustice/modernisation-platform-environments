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

output "grafana_cloud_pdc_private_connectivity" {
  description = "Endpoint service and DNS names for the VPC owner to configure PDC over AWS PrivateLink."
  value = {
    api = {
      service_name = grafana_cloud_stack.observability_platform.pdc_api_private_connectivity_info_service_name
      private_dns  = grafana_cloud_stack.observability_platform.pdc_api_private_connectivity_info_private_dns
    }
    gateway = {
      service_name = grafana_cloud_stack.observability_platform.pdc_gateway_private_connectivity_info_service_name
      private_dns  = grafana_cloud_stack.observability_platform.pdc_gateway_private_connectivity_info_private_dns
    }
  }
}

output "events_api_endpoint" {
  description = "Base URL of the events API. Publish with POST <endpoint>/events/<event-name>"
  value       = module.api_gateway.api_endpoint
}

output "events_api_url" {
  description = "Stable custom-domain URL of the events API. Set EVENTS_PLATFORM_URL to this in consumers"
  value       = "https://${local.api_domain}"
}

output "events_parent_zone_name_servers" {
  description = "Name servers of the parent zone events-platform.service.justice.gov.uk. Needed when requesting delegation"
  value       = data.aws_route53_zone.events_parent.name_servers
}

output "event_bus_name" {
  description = "Name of the EventBridge bus that subscribers attach rules to"
  value       = module.eventbridge_bus.eventbridge_bus_name
}

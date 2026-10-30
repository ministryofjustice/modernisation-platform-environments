output "events_api_endpoint" {
  description = "Base URL of the events API. Publish with POST <endpoint>/events/<event-name>"
  value       = module.api_gateway.api_endpoint
}

output "event_bus_name" {
  description = "Name of the EventBridge bus that subscribers attach rules to"
  value       = module.eventbridge_bus.eventbridge_bus_name
}

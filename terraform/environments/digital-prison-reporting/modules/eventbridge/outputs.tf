output "event_bus_arn" {
  description = "ARN of the Custom Event Bus"
  value       = try(aws_cloudwatch_event_bus.this.arn, "")
}
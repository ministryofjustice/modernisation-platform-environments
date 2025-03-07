output "event_bus_arn" {
  description = "ARN of the Custom Event Bus"
  value       = aws_cloudwatch_event_bus.this.arn
}
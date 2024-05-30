output "dashboard_widgets" {
  description = "local widgets list for debugging purposes"
  value       = local.widgets
}

output "dashboard" {
  description = "aws_cloudwatch_dashboard resource"
  value       = aws_cloudwatch_dashboard.this
}

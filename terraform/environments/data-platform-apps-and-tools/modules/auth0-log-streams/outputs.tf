output "cloudwatch_log_group_arn" {
  value = aws_cloudwatch_log_group.this.arn
}

output "cloudwatch_log_group_name" {
  value = local.cloudwatch_log_group_name
}

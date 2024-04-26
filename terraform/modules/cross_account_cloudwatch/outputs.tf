output "sink_arn" {
  description = "The ARN of CloudWatch OAM sink"
  value       = aws_oam_sink.monitoring_account_oam_sink[0].arn
}

output "monitoring_account_sink_identifier" {
  value = var.options.enable_cloudwatch_monitoring_account ? "${aws_oam_sink.monitoring_account_oam_sink[0].arn}" : null
}

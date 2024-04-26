locals {
    monitoring_account_sink_identifier = var.options.enable_cloudwatch_cross_account_sharing ? "${aws_oam_sink.monitoring_account_oam_sink[0].arn}" : null
}

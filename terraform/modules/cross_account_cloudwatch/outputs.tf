output "monitoring_account_sink_identifier" {
    value = "${aws_oam_sink.monitoring_account_oam_sink[0].arn}"
}

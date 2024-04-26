resource "aws_oam_sink" "monitoring_account_oam_sink" {
  count = var.options.enable_cloudwatch_monitoring_account ? 1 : 0
  name  = "MonitoringAccountSink"
}

resource "aws_oam_sink_policy" "monitoring_account_oam_sink_policy" {
  count           = var.options.enable_cloudwatch_monitoring_account ? 1 : 0
  sink_identifier = aws_oam_sink.monitoring_account_oam_sink[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["oam:CreateLink", "oam:UpdateLink"]
        Effect   = "Allow"
        Resource = "*"
        Principal = {
          "AWS" = var.source_account_ids
        }
        Condition = {
          "ForAllValues:StringEquals" = {
            "oam:ResourceTypes" = ["AWS::CloudWatch::Metric"]
          }
        }
      }
    ]
  })
}

output "sink_arn" {
  value = var.options.enable_cloudwatch_monitoring_account ? "${aws_oam_sink.monitoring_account_oam_sink[0].arn}" : null
}

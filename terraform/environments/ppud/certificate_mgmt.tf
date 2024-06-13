##########################################################
# EventBridge rules for certificate approaching expiration
##########################################################

resource "aws_cloudwatch_event_rule" "certificate-approaching-expiration-uat" {
  count               = local.is-preproduction == true ? 1 : 0
  name                = "Certificate-Approaching-Expiration"
  description         = "PPUD certificate is approaching expiration"
  event_pattern = jsonencode({
    "source": ["aws.acm"],
    "detail-type": ["ACM Certificate Approaching Expiration"]
  })
}

resource "aws_cloudwatch_event_target" "certificate-approaching-expiration-target-uat" {
  count     = local.is-preproduction == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.certificate-approaching-expiration[0].name
  target_id = "ec2_cloudwatch_alarms"
  arn       = aws_sns_topic.ec2_cloudwatch_alarms.[0].arn
}

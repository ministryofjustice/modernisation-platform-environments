data "aws_sns_topic" "s3_topic" {
  name = "s3-event-notification-topic"
}

data "aws_sns_topic" "cw_alerts" {
  name = "ccms-ebs-ec2-alerts"
}

data "aws_s3_bucket" "logging_bucket" {
  bucket = "${local.application_name}-${local.environment}-logging"
}

# PROD DNS Zones
data "aws_route53_zone" "laa" {
  provider     = aws.core-network-services
  name         = "laa.service.justice.gov.uk"
  private_zone = false
}
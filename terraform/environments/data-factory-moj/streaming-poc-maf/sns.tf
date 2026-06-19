module "sns_drone_incursion_alerts" {
  source  = "terraform-aws-modules/sns/aws"
  version = "~> 7.0"

  name              = "moj-pov-drone-incursion-alerts"
  kms_master_key_id = aws_kms_key.sns[0].key_id

  topic_policy_statements = {
    deny_non_ssl = {
      sid     = "DenyNonSSL"
      effect  = "Deny"
      actions = ["sns:Publish"]
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/flink-rules-flink-iam-role"]
      }]
      conditions = [{
        test     = "Bool"
        variable = "aws:SecureTransport"
        values   = ["false"]
      }]
    }
    allow_flink_publish = {
      sid     = "AllowFlinkPublish"
      effect  = "Allow"
      actions = ["sns:Publish"]
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/flink-rules-flink-iam-role"]
      }]
    }
  }
}

resource "aws_sns_topic_subscription" "drone_incursion_alert_emails" {
  for_each = toset(local.drone_incursion_alert_emails)

  topic_arn = module.sns_drone_incursion_alerts.topic_arn
  protocol  = "email"
  endpoint  = each.value
}

# TODO: uncomment when we have sender ID and are out of sandbox mode.
# resource "aws_sns_topic_subscription" "drone_incursion_alert_sms" {
#   for_each = toset(local.drone_incursion_alert_phone_numbers)
#
#   topic_arn = module.sns_drone_incursion_alerts.topic_arn
#   protocol  = "sms"
#   endpoint  = each.value
# }
#
# resource "aws_sns_sms_preferences" "alerts" {
#   default_sms_type    = "Transactional"
#   default_sender_id   = local.sns_sender_id
#   monthly_spend_limit = local.sns_monthly_spending_limit
# }

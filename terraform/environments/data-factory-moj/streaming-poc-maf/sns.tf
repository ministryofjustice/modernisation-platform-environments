#checkov:skip=CKV_TF_1:terraform-aws-modules uses version pinning which is the recommended approach for registry modules
module "sns_drone_incursion_alerts" {
  count   = contains(local.deploy_to, local.environment) ? 1 : 0
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
        identifiers = [module.flink_rules[0].flink_role_arn]
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
        identifiers = [module.flink_rules[0].flink_role_arn]
      }]
    }
  }
}

resource "aws_sns_topic_subscription" "drone_incursion_alert_emails" {
  for_each = contains(local.deploy_to, local.environment) ? toset(local.drone_incursion_alert_emails) : toset([])

  topic_arn = module.sns_drone_incursion_alerts[0].topic_arn
  protocol  = "email"
  endpoint  = each.value
}

# TODO: uncomment when we have sender ID and are out of sandbox mode.
# resource "aws_sns_topic_subscription" "drone_incursion_alert_sms" {
#   for_each = contains(local.deploy_to, local.environment) ? toset(local.drone_incursion_alert_phone_numbers) : toset([])
#
#   topic_arn = module.sns_drone_incursion_alerts[0].topic_arn
#   protocol  = "sms"
#   endpoint  = each.value
# }
#
# resource "aws_sns_sms_preferences" "alerts" {
#   count  = contains(local.deploy_to, local.environment) ? 1 : 0
#   default_sms_type    = "Transactional"
#   default_sender_id   = local.sns_sender_id
#   monthly_spend_limit = local.sns_monthly_spending_limit
# }

locals {
  pattern_name       = "${local.application_name}-${local.component_name}"
  pickup_bucket_name = "${local.application_name}-pickup-${local.environment}-${data.aws_caller_identity.current.account_id}"
  recipients         = module.dispatch_configuration.pickup_recipients
  portal_url         = local.is-production ? "https://web.file-transfer.service.justice.gov.uk" : "https://web.${local.environment}.file-transfer.service.justice.gov.uk"
  routes = { for id, recipient in local.recipients : data.aws_secretsmanager_secret.dispatch[id].arn => {
    recipient_id           = id
    prefix                 = recipient.prefix
    notification_topic_arn = module.sns_slack[id].topic_arn
  } }
}
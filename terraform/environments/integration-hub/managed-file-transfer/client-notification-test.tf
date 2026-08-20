module "sqs_products_poc_clean_file_ready_notifications" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.2"

  count = local.environment == "development" ? 1 : 0

  name            = "${local.application_name}-products-poc-clean-file-ready"
  use_name_prefix = false

  create_queue_policy = true
  queue_policy_statements = {
    sns = {
      sid     = "AllowClientNotificationTopicSendMessage"
      actions = ["sqs:SendMessage"]

      principals = [
        {
          type        = "Service"
          identifiers = ["sns.amazonaws.com"]
        }
      ]

      condition = [
        {
          test     = "ArnEquals"
          variable = "aws:SourceArn"
          values   = [module.proof_of_concept_notification.sns_clean_file_client_notifications.topic_arn]
        }
      ]
    }
  }

  create_dlq = true
  dlq_name   = "${local.application_name}-products-poc-clean-file-ready-dlq"

  message_retention_seconds     = 1209600
  visibility_timeout_seconds    = 180
  receive_wait_time_seconds     = 20
  dlq_message_retention_seconds = 1209600

  redrive_policy = {
    maxReceiveCount = 5
  }

  tags = local.tags
}

resource "aws_sns_topic_subscription" "products_poc_clean_file_ready_notifications" {
  count = local.environment == "development" ? 1 : 0

  topic_arn            = module.proof_of_concept_notification.sns_clean_file_client_notifications.topic_arn
  protocol             = "sqs"
  endpoint             = module.sqs_products_poc_clean_file_ready_notifications[0].queue_arn
  raw_message_delivery = true

  filter_policy = jsonencode({
    clientId = ["products-poc"]
  })
}

module "eventbridge_notifications" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "4.3.2"

  bus_name                   = data.aws_cloudwatch_event_bus.file_transfer.name
  create_bus                 = false
  create_log_delivery        = false
  create_log_delivery_source = false
  append_rule_postfix        = false
  create_role                = false

  rules = {
    "pull-from-presigned-url" = {
      description = "Route pull-from-presigned-url file action requests"
      event_pattern = jsonencode({
        account       = [data.aws_caller_identity.current.account_id]
        source        = ["uk.gov.justice.service.managed-file-transfer"]
        "detail-type" = ["FileActionExecutionRequested.v1"]
        detail = {
          data = {
            notifications = ["slack"]
            configurationReference = {
              secretArn = length(local.routes) > 0 ? keys(local.routes) : ["unconfigured"]
            }
          }
        }
      })
    }
  }

  targets = {
    "pull-from-presigned-url" = [{
      name            = "pull-from-presigned-url"
      arn             = module.sns_notifications.topic_arn
      dead_letter_arn = module.sqs_notifications_eventbridge_dlq.queue_arn
      retry_policy = {
        maximum_event_age_in_seconds = 21600
        maximum_retry_attempts       = 185
      }
    }]
  }

  tags = local.tags
}
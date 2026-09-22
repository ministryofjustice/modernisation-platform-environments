module "eventbridge_hosted_pickup" {
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
    "push-to-s3-with-hosted-pickup" = {
      description = "Route push-to-s3-with-hosted-pickup file action requests"
      event_pattern = jsonencode({
        account       = [data.aws_caller_identity.current.account_id]
        source        = ["uk.gov.justice.service.managed-file-transfer"]
        "detail-type" = ["FileActionExecutionRequested.v1"]
        detail = {
          data = {
            action = {
              name = ["push-to-s3-with-hosted-pickup"]
            }
          }
        }
      })
    }
  }

  targets = {
    "push-to-s3-with-hosted-pickup" = [{
      name            = "push-to-s3-with-hosted-pickup"
      arn             = module.sns_hosted_pickup.topic_arn
      dead_letter_arn = module.sqs_hosted_pickup_dlq.queue_arn
      retry_policy = {
        maximum_event_age_in_seconds = 21600
        maximum_retry_attempts       = 185
      }
    }]
  }

  tags = local.tags
}
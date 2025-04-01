module "transfer_service_eventbridge" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/eventbridge/aws"
  version = "3.14.5"

  create_bus = false

  # TBC if this is the correct way to do it
  # attach_lambda_policy = true
  # lambda_target_arns   = [module.transfer_service_lambda.lambda_function_arn]

  rules = {
    transfer-service = {
      description = "Transfer Service Event Rule"
      enabled     = true
      event_pattern = jsonencode({
        source = ["aws.guardduty"]
        detail = {
          eventName = ["GuardDuty Malware Protection Object Scan Result"]
        }
      })
    }
  }

  targets = {
    transfer-service = [
      {
        name = "transfer-service-lambda-target"
        arn  = module.transfer_service_lambda.lambda_function_arn
      }
    ]
  }
}

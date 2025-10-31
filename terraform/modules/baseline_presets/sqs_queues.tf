locals {

  sqs_queues = merge(
    var.options.enable_xsiam_s3_integration ? {
      cortex-xsiam-s3-alb-log-collection = {
        policy = [
          {
            effect = "Allow"
            actions = [
              "sqs:SendMessage",
            ]
            principals = {
              type        = "Service"
              identifiers = ["s3.amazonaws.com"]
            }
            conditions = [{
              test     = "ForAnyValue:ArnLike"
              variable = "aws:SourceArn"
              values   = ["arn:aws:s3:::*logs*"]
            }]
          },
          {
            effect = "Allow"
            actions = [
              "sqs:ChangeMessageVisibility",
              "sqs:DeleteMessage",
              "sqs:ReceiveMessage"
            ]
            principals = {
              type        = "AWS"
              identifiers = ["arn:aws:iam::${var.environment.account_id}:role/CortexXsiamS3AccessRole"]
            }
          }
        ]
      }
    } : {}
  )
}

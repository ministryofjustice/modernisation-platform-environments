module "sqs_s3_notifications" {
  count = local.create_resources ? 1 : 0

  source = "terraform-aws-modules/sqs/aws"
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  version             = "5.1.0"
  create_queue_policy = true
  queue_policy_statements = {
    s3 = {
      "Sid" : "AllowSendMessage",
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "s3.amazonaws.com"
      },
      "Action" : "sqs:SendMessage",
      "Resource" : module.sqs_s3_notifications[0].queue_arn,
      "Condition" : {
        "ArnEquals" : {
          "aws:SourceArn" : module.s3_bucket_workspacesweb_session_logs[0].s3_bucket_arn
        }
      }
    }
  }
}
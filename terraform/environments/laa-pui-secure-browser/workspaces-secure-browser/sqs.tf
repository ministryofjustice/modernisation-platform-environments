module "sqs_s3_notifications" {
  source = "terraform-aws-modules/sqs/aws"
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  version = "5.1.0"

  count               = local.create_resources ? 1 : 0
  create_queue_policy = true
  name                = local.component_name

  queue_policy_statements = {
    s3 = {
      sid     = "AllowS3SendMessage"
      actions = ["sqs:SendMessage"]
      principals = [
        { type = "Service", identifiers = ["s3.amazonaws.com"] }
      ]
      condition = [
        {
          test     = "ArnLike"
          variable = "aws:SourceArn"
          values   = [module.s3_bucket_workspacesweb_session_logs[0].s3_bucket_arn]
        },
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    }
  }
}

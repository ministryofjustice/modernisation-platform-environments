module "cortex_xsiam_sqs" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-sqs.git?ref=dd73a96c0155bc324dda5256f3e7a9ea2c710195" # v5.2.2

  name                = "${local.component_name}-cortex-xsiam"
  create_dlq          = true
  create_queue_policy = true

  kms_master_key_id             = module.kms_key[0].key_arn
  dlq_kms_master_key_id         = module.kms_key[0].key_arn
  message_retention_seconds     = 1209600
  dlq_message_retention_seconds = 1209600
  receive_wait_time_seconds     = 20

  redrive_policy = {
    maxReceiveCount = 5
  }

  queue_policy_statements = {
    s3_publish = {
      sid        = "AllowS3ObjectNotifications"
      actions    = ["sqs:SendMessage"]
      principals = [{ type = "Service", identifiers = ["s3.amazonaws.com"] }]
      conditions = [
        { test = "ArnEquals", variable = "aws:SourceArn", values = [module.s3_bucket[0].s3_bucket_arn] },
        { test = "StringEquals", variable = "aws:SourceAccount", values = [data.aws_caller_identity.current.account_id] }
      ]
    }
  }
}

module "cortex_xsiam_s3_notification" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git//modules/notification?ref=dd0c434de5e74d8864e249ee020d917b076b6e32" # v5.15.4

  bucket                   = module.s3_bucket[0].s3_bucket_id
  create_sqs_policy        = false
  create_sns_policy        = false
  create_lambda_permission = false

  sqs_notifications = {
    cortex_xsiam = {
      queue_arn = module.cortex_xsiam_sqs[0].queue_arn
      queue_id  = module.cortex_xsiam_sqs[0].queue_url
      events    = ["s3:ObjectCreated:*"]
    }
  }
}
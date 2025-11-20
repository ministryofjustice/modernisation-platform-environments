resource "random_uuid" "cortex" {}

module "cortex_xsiam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> 6.2"

  count           = local.create_resources ? 1 : 0
  name            = "cortex_xsiam"
  use_name_prefix = true
  description     = "Role utilised by Palo Alto Cortex XSIAM"

  # Allow Cortex account root to assume role with ExternalId
  trust_policy_permissions = {
    CortexXSIAM = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${aws_ssm_parameter.cortex_account_id[0].insecure_value}:root"]
      }]
      condition = [{
        test     = "StringEquals"
        variable = "sts:ExternalId"
        values   = [sensitive(random_uuid.cortex.result)]
      }]
    }
  }

  create_inline_policy = true
  inline_policy_permissions = {
    SQSQueueReceiveMessages = {
      effect = "Allow"
      actions = [
        "sqs:ChangeMessageVisibility",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ListQueues",
      ]
      resources = [module.sqs_xsiam_notifications[0].queue_arn]
    }
    S3GetLogs = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectVersion"
      ]
      resources = ["${module.s3_bucket_workspacesweb_session_logs[0].s3_bucket_arn}/*"]
    }
    KMSUseKey = {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey"
      ]
      resources = [aws_kms_key.workspacesweb_session_logs[0].arn]
    }
  }

  tags = local.tags
}
locals {
  file_received_workflow_maximum_size_bytes = 5000000000000
  file_received_workflow_part_size_bytes    = 5000000000
  file_received_workflow_timeout_seconds    = 86400
  file_received_workflow_lease_seconds      = local.file_received_workflow_timeout_seconds + 3600
}

module "step_function_file_received_workflow" {
  source  = "terraform-aws-modules/step-functions/aws"
  version = "5.1.0"

  name = "${local.application_name}-${local.environment}-file-received-workflow"
  type = "STANDARD"

  definition = templatefile("${path.module}/step-functions/file-received-workflow.asl.json", {
    account_id                 = jsonencode(data.aws_caller_identity.current.account_id)
    destination_kms_key_arn    = jsonencode(module.kms_s3_bucket["processing"].key_arn)
    idempotency_table_name     = jsonencode(module.dynamodb_file_received_workflow_idempotency.dynamodb_table_id)
    incoming_bucket_name       = jsonencode(module.s3_bucket["incoming"].s3_bucket_id)
    lease_seconds              = local.file_received_workflow_lease_seconds
    maximum_size_bytes         = local.file_received_workflow_maximum_size_bytes
    multipart_max_concurrency  = 4
    part_size_bytes            = local.file_received_workflow_part_size_bytes
    processing_bucket_name     = jsonencode(module.s3_bucket["processing"].s3_bucket_id)
    record_retention_seconds   = local.eventbridge_retention_days * 24 * 60 * 60
    state_machine_timeout_secs = local.file_received_workflow_timeout_seconds
  })

  logging_configuration = {
    include_execution_data = false
    level                  = "ALL"
  }

  cloudwatch_log_group_name              = "/aws/vendedlogs/states/${local.application_name}-${local.environment}-file-received-workflow"
  cloudwatch_log_group_retention_in_days = local.eventbridge_retention_days
  cloudwatch_log_group_kms_key_id        = module.kms_cloudwatch_logs.key_arn
  cloudwatch_log_group_tags              = local.tags

  attach_policy_statements = true
  policy_statements = {
    workflow_idempotency = {
      effect = "Allow"
      actions = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
      ]
      resources = [module.dynamodb_file_received_workflow_idempotency.dynamodb_table_arn]
    }
    incoming_object_read = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:GetObjectVersion",
        "s3:GetObjectVersionTagging",
      ]
      resources = ["${module.s3_bucket["incoming"].s3_bucket_arn}/*"]
    }
    incoming_object_delete = {
      effect    = "Allow"
      actions   = ["s3:DeleteObjectVersion"]
      resources = ["${module.s3_bucket["incoming"].s3_bucket_arn}/*"]
    }
    processing_object = {
      effect = "Allow"
      actions = [
        "s3:AbortMultipartUpload",
        "s3:DeleteObjectVersion",
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:GetObjectVersion",
        "s3:GetObjectVersionTagging",
        "s3:ListMultipartUploadParts",
        "s3:PutObject",
        "s3:PutObjectTagging",
      ]
      resources = ["${module.s3_bucket["processing"].s3_bucket_arn}/*"]
    }
    incoming_kms = {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [module.kms_s3_bucket["incoming"].key_arn]
    }
    processing_kms = {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
      ]
      resources = [module.kms_s3_bucket["processing"].key_arn]
    }
  }

  tags = local.tags
}
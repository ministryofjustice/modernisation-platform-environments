module "step_function_filereceived_workflow" {
  source  = "terraform-aws-modules/step-functions/aws"
  version = "5.1.0"

  name = "${local.environment}-filereceived-workflow"
  type = "STANDARD"

  definition = templatefile("${path.module}/step-functions/filereceived-workflow.asl.json", {
    account_id                = jsonencode(data.aws_caller_identity.current.account_id)
    event_bus_arn             = jsonencode(local.file_transfer_event_bus_arn)
    idempotency_table_name    = jsonencode(module.dynamodb_file_transfer_idempotency.dynamodb_table_id)
    multipart_max_concurrency = 4
    part_size_bytes           = local.file_transfer_workflow_part_size_bytes
    processing_bucket_name    = jsonencode(module.s3_bucket["processing"].s3_bucket_id)
    processing_kms_key_arn    = jsonencode(module.kms_s3_bucket["processing"].key_arn)
    record_retention_seconds  = local.cloudwatch_retention_days * 24 * 60 * 60
    timeout_seconds           = local.file_transfer_workflow_timeout_seconds
  })

  logging_configuration = {
    include_execution_data = false
    level                  = "ALL"
  }

  cloudwatch_log_group_name              = "/aws/vendedlogs/states/${local.application_name}-${local.environment}-filereceived-workflow"
  cloudwatch_log_group_retention_in_days = local.cloudwatch_retention_days
  cloudwatch_log_group_kms_key_id        = module.kms_cloudwatch_logs.key_arn
  cloudwatch_log_group_tags              = local.tags

  attach_policy_statements = true
  policy_statements = {
    workflow_idempotency = {
      effect    = "Allow"
      actions   = ["dynamodb:UpdateItem"]
      resources = [module.dynamodb_file_transfer_idempotency.dynamodb_table_arn]
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
    publish_workflow_events = {
      effect    = "Allow"
      actions   = ["events:PutEvents"]
      resources = [local.file_transfer_event_bus_arn]
    }
  }

  tags = local.tags
}

module "step_function_filescanresultrecorded_workflow" {
  source  = "terraform-aws-modules/step-functions/aws"
  version = "5.1.0"

  name = "${local.environment}-filescanresultrecorded-workflow"
  type = "STANDARD"

  definition = templatefile("${path.module}/step-functions/filescanresultrecorded-workflow.asl.json", {
    account_id                = jsonencode(data.aws_caller_identity.current.account_id)
    clean_bucket_name         = jsonencode(module.s3_bucket["clean"].s3_bucket_id)
    clean_kms_key_arn         = jsonencode(module.kms_s3_bucket["clean"].key_arn)
    event_bus_arn             = jsonencode(local.file_transfer_event_bus_arn)
    idempotency_table_name    = jsonencode(module.dynamodb_file_transfer_idempotency.dynamodb_table_id)
    investigation_bucket_name = jsonencode(module.s3_bucket["investigation"].s3_bucket_id)
    investigation_kms_key_arn = jsonencode(module.kms_s3_bucket["investigation"].key_arn)
    multipart_max_concurrency = 4
    part_size_bytes           = local.file_transfer_workflow_part_size_bytes
    quarantine_bucket_name    = jsonencode(module.s3_bucket["quarantine"].s3_bucket_id)
    quarantine_kms_key_arn    = jsonencode(module.kms_s3_bucket["quarantine"].key_arn)
    record_retention_seconds  = local.cloudwatch_retention_days * 24 * 60 * 60
    timeout_seconds           = local.file_transfer_workflow_timeout_seconds
  })

  logging_configuration = {
    include_execution_data = false
    level                  = "ALL"
  }

  cloudwatch_log_group_name              = "/aws/vendedlogs/states/${local.application_name}-${local.environment}-filescanresultrecorded-workflow"
  cloudwatch_log_group_retention_in_days = local.cloudwatch_retention_days
  cloudwatch_log_group_kms_key_id        = module.kms_cloudwatch_logs.key_arn
  cloudwatch_log_group_tags              = local.tags

  attach_policy_statements = true
  policy_statements = {
    workflow_idempotency = {
      effect    = "Allow"
      actions   = ["dynamodb:UpdateItem"]
      resources = [module.dynamodb_file_transfer_idempotency.dynamodb_table_arn]
    }
    processing_object_read = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:GetObjectVersion",
        "s3:GetObjectVersionTagging",
      ]
      resources = ["${module.s3_bucket["processing"].s3_bucket_arn}/*"]
    }
    processing_object_delete = {
      effect    = "Allow"
      actions   = ["s3:DeleteObjectVersion"]
      resources = ["${module.s3_bucket["processing"].s3_bucket_arn}/*"]
    }
    routing_destination_objects = {
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:PutObjectTagging",
      ]
      resources = [
        "${module.s3_bucket["clean"].s3_bucket_arn}/*",
        "${module.s3_bucket["quarantine"].s3_bucket_arn}/*",
        "${module.s3_bucket["investigation"].s3_bucket_arn}/*",
      ]
    }
    processing_kms = {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [module.kms_s3_bucket["processing"].key_arn]
    }
    routing_destination_kms = {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
      ]
      resources = [
        module.kms_s3_bucket["clean"].key_arn,
        module.kms_s3_bucket["quarantine"].key_arn,
        module.kms_s3_bucket["investigation"].key_arn,
      ]
    }
    publish_workflow_events = {
      effect    = "Allow"
      actions   = ["events:PutEvents"]
      resources = [local.file_transfer_event_bus_arn]
    }
  }

  tags = local.tags
}
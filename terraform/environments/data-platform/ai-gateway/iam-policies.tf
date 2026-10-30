locals {
  ai_gateway_bedrock_batch_region  = try(local.ai_gateway_batch_storage.region, data.aws_region.current.region)
  ai_gateway_bedrock_batch_job_arn = "arn:aws:bedrock:${local.ai_gateway_bedrock_batch_region}:${data.aws_caller_identity.current.account_id}:model-invocation-job/*"

  ai_gateway_bedrock_assume_role_arns = distinct([
    for model in values(try(local.ai_gateway_models_filtered.amazon_bedrock, {})) :
    "arn:aws:iam::${local.environment_management.account_ids[model.aws_account_name]}:role/${model.aws_role_name}"
    if can(model.aws_account_name) && can(model.aws_role_name)
  ])
}

data "aws_iam_policy_document" "ai_gateway" {
  statement {
    sid    = "AwsMarketplaceAccess"
    effect = "Allow"
    actions = [
      "aws-marketplace:Subscribe",
      "aws-marketplace:ViewSubscriptions"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "BedrockInferenceProfileAccess"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel*"]
    resources = formatlist("arn:aws:bedrock:%s:${data.aws_caller_identity.current.account_id}:inference-profile/*", ["eu-west-1", "eu-west-2"])
  }

  statement {
    sid       = "BedrockFoundationModelAccess"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel*"]
    resources = ["arn:aws:bedrock:eu-*::foundation-model/*"]
  }

  statement {
    sid     = "BedrockGuardrailAccess"
    effect  = "Allow"
    actions = ["bedrock:ApplyGuardrail"]
    resources = [
      "arn:aws:bedrock:*:${data.aws_caller_identity.current.account_id}:guardrail/*",
      "arn:aws:bedrock:eu-west-2:${data.aws_caller_identity.current.account_id}:guardrail-profile/uk.guardrail.v1:0"
    ]
  }

  dynamic "statement" {
    for_each = { for sid, permissions in {
      BedrockCreateBatchInferenceJob = {
        actions = ["bedrock:CreateModelInvocationJob"]
        resources = concat(
          formatlist("arn:aws:bedrock:%s:${data.aws_caller_identity.current.account_id}:inference-profile/*", ["eu-west-1", "eu-west-2"]),
          ["arn:aws:bedrock:eu-*::foundation-model/*"],
          [local.ai_gateway_bedrock_batch_job_arn]
        )
      }
      BedrockManageBatchInferenceJobs = {
        actions = [
          "bedrock:GetModelInvocationJob",
          "bedrock:StopModelInvocationJob",
          "bedrock:TagResource",
          "bedrock:UntagResource",
          "bedrock:ListTagsForResource"
        ]
        resources = [local.ai_gateway_bedrock_batch_job_arn]
      }
      BedrockListBatchInferenceJobs = {
        actions   = ["bedrock:ListModelInvocationJobs"]
        resources = ["*"]
      }
    } : sid => permissions if local.ai_gateway_batch_storage != null }

    content {
      sid       = statement.key
      effect    = "Allow"
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }

  dynamic "statement" {
    for_each = local.ai_gateway_batch_storage != null ? [1] : []

    content {
      sid       = "PassBedrockBatchExecutionRole"
      effect    = "Allow"
      actions   = ["iam:PassRole"]
      resources = [aws_iam_role.bedrock_batch_execution[0].arn]

      condition {
        test     = "StringEquals"
        variable = "iam:PassedToService"
        values   = ["bedrock.amazonaws.com"]
      }
    }
  }

  dynamic "statement" {
    for_each = local.ai_gateway_batch_storage == null ? {} : {
      BatchInferenceListBuckets = {
        actions   = ["s3:ListBucket"]
        resources = distinct(values(local.ai_gateway_batch_bucket_arns))
      }
      BatchInferenceReadWriteInput = {
        actions   = ["s3:GetObject", "s3:PutObject"]
        resources = [local.ai_gateway_batch_object_arns.input]
      }
      BatchInferenceReadOutput = {
        actions   = ["s3:GetObject"]
        resources = [local.ai_gateway_batch_object_arns.output]
      }
    }

    content {
      sid       = statement.key
      effect    = "Allow"
      actions   = statement.value.actions
      resources = statement.value.resources

      # Bucket names are global; reject a same-named bucket recreated in another account
      condition {
        test     = "StringEquals"
        variable = "s3:ResourceAccount"
        values   = [local.ai_gateway_batch_storage.bucket_owner]
      }
    }
  }

  dynamic "statement" {
    for_each = local.ai_gateway_batch_storage == null ? [] : [local.ai_gateway_batch_storage.output_kms_key_arn]

    content {
      sid       = "BatchInferenceKMSAccess"
      effect    = "Allow"
      actions   = ["kms:GenerateDataKey", "kms:Decrypt", "kms:DescribeKey"]
      resources = [statement.value]
    }
  }

  statement {
    sid       = "AuditLogS3Access"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${module.audit_logs.s3_bucket_arn}/litellm-audit/audit_logs/*"]
  }

  statement {
    sid    = "AuditLogKMSAccess"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]
    resources = [module.ai_gateway_audit_logs_kms_key.key_arn]
  }

  statement {
    sid    = "RDSIAMConnect"
    effect = "Allow"
    actions = [
      "rds-db:connect"
    ]
    resources = [
      "arn:aws:rds-db:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:dbuser:*/litellm"
    ]
  }

  dynamic "statement" {
    for_each = length(local.ai_gateway_bedrock_assume_role_arns) > 0 ? [1] : []

    content {
      sid       = "AssumeAmazonBedrockModelRoles"
      effect    = "Allow"
      actions   = ["sts:AssumeRole"]
      resources = local.ai_gateway_bedrock_assume_role_arns
    }
  }
}

module "ai_gateway_iam_policy" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=1d73bcb359419e1b41872ac5ccaf8808b8f1150e" # v6.6.0

  name_prefix = local.component_name

  policy = data.aws_iam_policy_document.ai_gateway.json
}

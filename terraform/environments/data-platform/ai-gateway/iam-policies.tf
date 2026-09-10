locals {
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

  # Lets the pod submit batch inference jobs against the same models it can already invoke directly
  statement {
    sid     = "BedrockCreateBatchInferenceJob"
    effect  = "Allow"
    actions = ["bedrock:CreateModelInvocationJob"]
    resources = concat(
      formatlist("arn:aws:bedrock:%s:${data.aws_caller_identity.current.account_id}:inference-profile/*", ["eu-west-1", "eu-west-2"]),
      ["arn:aws:bedrock:eu-*::foundation-model/*"],
      ["arn:aws:bedrock:eu-west-2:${data.aws_caller_identity.current.account_id}:model-invocation-job/*"]
    )
  }

  statement {
    sid    = "BedrockManageBatchInferenceJobs"
    effect = "Allow"
    actions = [
      "bedrock:GetModelInvocationJob",
      "bedrock:StopModelInvocationJob"
    ]
    resources = ["arn:aws:bedrock:eu-west-2:${data.aws_caller_identity.current.account_id}:model-invocation-job/*"]
  }

  # ListModelInvocationJobs/TagResource/etc. don't support resource-level scoping
  statement {
    sid    = "BedrockListBatchInferenceJobs"
    effect = "Allow"
    actions = [
      "bedrock:ListModelInvocationJobs",
      "bedrock:TagResource",
      "bedrock:UntagResource",
      "bedrock:ListTagsForResource"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "PassBedrockBatchExecutionRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.bedrock_batch_execution.arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["bedrock.amazonaws.com"]
    }
  }

  statement {
    sid    = "BatchInferenceS3Access"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      module.batch_inference.s3_bucket_arn,
      "${module.batch_inference.s3_bucket_arn}/*"
    ]
  }

  statement {
    sid    = "BatchInferenceKMSAccess"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]
    resources = [module.ai_gateway_batch_inference_kms_key.key_arn]
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

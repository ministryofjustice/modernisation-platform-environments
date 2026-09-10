# Service role that Bedrock (not the AI Gateway pod) assumes while a batch inference job runs,
# to read the input file from and write results to the batch inference bucket.
data "aws_iam_policy_document" "bedrock_batch_execution_trust" {
  statement {
    sid     = "AllowBedrockAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:bedrock:eu-west-2:${data.aws_caller_identity.current.account_id}:model-invocation-job/*"]
    }
  }
}

data "aws_iam_policy_document" "bedrock_batch_execution_permissions" {
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

  # Bedrock invokes the model using this role during the job, mirroring the invoke
  # permissions already granted to the AI Gateway pod role in iam-policies.tf
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
}

module "bedrock_batch_execution_iam_policy" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=1d73bcb359419e1b41872ac5ccaf8808b8f1150e" # v6.6.0

  name_prefix = "${local.component_name}-bedrock-batch-execution"

  policy = data.aws_iam_policy_document.bedrock_batch_execution_permissions.json
}

resource "aws_iam_role" "bedrock_batch_execution" {
  name               = "${local.component_name}-bedrock-batch-execution"
  assume_role_policy = data.aws_iam_policy_document.bedrock_batch_execution_trust.json
}

resource "aws_iam_role_policy_attachment" "bedrock_batch_execution" {
  role       = aws_iam_role.bedrock_batch_execution.name
  policy_arn = module.bedrock_batch_execution_iam_policy.arn
}

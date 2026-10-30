# Service role that Bedrock (not the AI Gateway pod) assumes while a batch inference job runs,
# to read from the input bucket and write results to the output bucket.
data "aws_iam_policy_document" "bedrock_batch_execution_trust" {
  count = local.ai_gateway_batch_storage != null ? 1 : 0

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
      values   = [local.ai_gateway_bedrock_batch_job_arn]
    }
  }
}

data "aws_iam_policy_document" "bedrock_batch_execution_permissions" {
  count = local.ai_gateway_batch_storage != null ? 1 : 0

  dynamic "statement" {
    for_each = {
      BatchInferenceListBuckets = {
        actions   = ["s3:ListBucket"]
        resources = distinct(values(local.ai_gateway_batch_bucket_arns))
      }
      BatchInferenceReadInput = {
        actions   = ["s3:GetObject"]
        resources = [local.ai_gateway_batch_object_arns.input]
      }
      BatchInferenceWriteOutput = {
        actions   = ["s3:PutObject"]
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

  statement {
    sid       = "BatchInferenceOutputKMSAccess"
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey", "kms:Decrypt", "kms:DescribeKey"]
    resources = [local.ai_gateway_batch_storage.output_kms_key_arn]
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
  count = local.ai_gateway_batch_storage != null ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=1d73bcb359419e1b41872ac5ccaf8808b8f1150e" # v6.6.0

  name_prefix = "${local.component_name}-bedrock-batch-execution"

  policy = data.aws_iam_policy_document.bedrock_batch_execution_permissions[0].json
}

resource "aws_iam_role" "bedrock_batch_execution" {
  count = local.ai_gateway_batch_storage != null ? 1 : 0

  name               = "${local.component_name}-bedrock-batch-execution"
  assume_role_policy = data.aws_iam_policy_document.bedrock_batch_execution_trust[0].json
}

resource "aws_iam_role_policy_attachment" "bedrock_batch_execution" {
  count = local.ai_gateway_batch_storage != null ? 1 : 0

  role       = aws_iam_role.bedrock_batch_execution[0].name
  policy_arn = module.bedrock_batch_execution_iam_policy[0].arn
}

moved {
  from = module.bedrock_batch_execution_iam_policy
  to   = module.bedrock_batch_execution_iam_policy[0]
}

moved {
  from = aws_iam_role.bedrock_batch_execution
  to   = aws_iam_role.bedrock_batch_execution[0]
}

moved {
  from = aws_iam_role_policy_attachment.bedrock_batch_execution
  to   = aws_iam_role_policy_attachment.bedrock_batch_execution[0]
}
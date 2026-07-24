### Bedrock Resources

## AI Gateway Cross Account Role
# Allows the production Data Platform AI Gateway to assume into this account and invoke Bedrock.
# Controlled per environment via application_variables.json enable_bedrock.

# AI Gateway Bedrock Assume Policy
data "aws_iam_policy_document" "ai_gateway_bedrock_assume" {
  count = local.enable_bedrock ? 1 : 0

  #checkov:skip=CKV_AWS_110:Ensure IAM policies does not allow privilege escalation
  #checkov:skip=CKV_AWS_107:Ensure IAM policies does not allow credentials exposure
  #checkov:skip=CKV_AWS_111:Ensure IAM policies does not allow write access without constraints
  #checkov:skip=CKV_AWS_356
  #checkov:skip=CKV_AWS_109
  #checkov:skip=CKV_AWS_1
  #checkov:skip=CKV_AWS_283
  #checkov:skip=CKV_AWS_49
  #checkov:skip=CKV_AWS_108

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [local.ai_gateway_role_arn]
    }
  }
}

# AI Gateway Bedrock Role
resource "aws_iam_role" "ai_gateway_bedrock" {
  count = local.enable_bedrock ? 1 : 0

  #checkov:skip=CKV_AWS_61:Ensure IAM policies does not allow data exfiltration
  #checkov:skip=CKV_AWS_60:Ensure IAM role allows only specific services or principals to assume it
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy

  name                  = "${local.project}-ai-gateway-bedrock-role"
  description           = "AI Gateway Bedrock Cross Account Role"
  assume_role_policy    = data.aws_iam_policy_document.ai_gateway_bedrock_assume[0].json
  force_detach_policies = true

  tags = merge(
    local.all_tags,
    {
      dpr-name           = "${local.project}-ai-gateway-bedrock-role"
      dpr-resource-type  = "iam"
      dpr-resource-group = "AI"
    }
  )
}

# AI Gateway Bedrock Permissions
data "aws_iam_policy_document" "ai_gateway_bedrock" {
  count = local.enable_bedrock ? 1 : 0

  #checkov:skip=CKV_AWS_111:Ensure IAM policies does not allow write access without constraints
  #checkov:skip=CKV_AWS_356
  #checkov:skip=CKV_AWS_109
  #checkov:skip=CKV_AWS_1
  #checkov:skip=CKV_AWS_283
  #checkov:skip=CKV_AWS_49
  #checkov:skip=CKV_AWS_108

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
    sid     = "BedrockInferenceProfileAccess"
    effect  = "Allow"
    actions = ["bedrock:InvokeModel*"]
    resources = formatlist(
      "arn:aws:bedrock:%s:${local.account_id}:inference-profile/*",
      ["eu-west-1", "eu-west-2"]
    )
  }

  statement {
    sid       = "BedrockFoundationModelAccess"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel*"]
    resources = ["arn:aws:bedrock:eu-*::foundation-model/*"]
  }
}

# AI Gateway Bedrock Policy
resource "aws_iam_policy" "ai_gateway_bedrock" {
  count = local.enable_bedrock ? 1 : 0

  name        = "${local.project}-ai-gateway-bedrock-policy"
  description = "Permissions for the AI Gateway to invoke Bedrock"
  policy      = data.aws_iam_policy_document.ai_gateway_bedrock[0].json
}

# AI Gateway Bedrock Role/Policy Attachment
resource "aws_iam_role_policy_attachment" "ai_gateway_bedrock" {
  count = local.enable_bedrock ? 1 : 0

  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy

  role       = aws_iam_role.ai_gateway_bedrock[0].name
  policy_arn = aws_iam_policy.ai_gateway_bedrock[0].arn
}

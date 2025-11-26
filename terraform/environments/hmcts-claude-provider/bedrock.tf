resource "aws_iam_policy" "bedrock_claude_policy" {
  name        = "HMCTSClaudeBedrockPolicy"
  description = "Policy for HMCTS Claude Provider Bedrock access"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "BedrockClaudeAccess",
        Effect = "Allow",
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
          "bedrock:GetInferenceProfile",
          "bedrock:ListInferenceProfiles",
          "bedrock:Get*",
          "bedrock:List*"
        ],
        Resource = [
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-opus-4-5-20251101-v1:0",
          "arn:aws:bedrock:eu-*::foundation-model/anthropic.claude-sonnet-4-5-20250929-v1:0",
          "arn:aws:bedrock:eu-*::foundation-model/anthropic.claude-sonnet-4-20250514-v1:0",
          "arn:aws:bedrock:eu-*::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0",
          "arn:aws:bedrock:us-*::foundation-model/anthropic.claude-3-5-haiku-20241022-v1:0",
          "arn:aws:bedrock:eu-*::foundation-model/anthropic.claude-3-5-haiku-20241022-v1:0",
          "arn:aws:bedrock:eu-*::foundation-model/anthropic.claude-3-haiku-20240307-v1:0",
          "arn:aws:bedrock:*::inference-profile/*",
          "arn:aws:bedrock:*:313941174580:inference-profile/*"
        ]
      },
      {
        Sid    = "BedrockBearerTokenAuth",
        Effect = "Allow",
        Action = "bedrock:CallWithBearerToken",
        Resource = "*"
      },
      {
        Sid    = "BedrockInferenceProfileManagement",
        Effect = "Allow",
        Action = [
          "bedrock:CreateInferenceProfile",
          "bedrock:DeleteInferenceProfile"
        ],
        Resource = [
          "arn:aws:bedrock:eu-west-1::foundation-model/anthropic.claude-sonnet-4-5-20250929-v1:0",
          "arn:aws:bedrock:eu-west-1::foundation-model/*",
          "arn:aws:bedrock:eu-west-1:*:application-inference-profile/*"
        ]
      },
      {
        Sid    = "BedrockModelAccess",
        Effect = "Allow",
        Action = [
          "bedrock:CreateFoundationModelAgreement",
          "bedrock:PutFoundationModelEntitlement",
          "bedrock:GetFoundationModelAvailability",
          "aws-marketplace:Subscribe",
          "aws-marketplace:Unsubscribe",
          "aws-marketplace:ViewSubscriptions"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "bedrock_service_role" {
  name = "HMCTSClaudeBedrockServiceRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = ["ec2.amazonaws.com", "lambda.amazonaws.com"]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bedrock_policy_attachment" {
  role       = aws_iam_role.bedrock_service_role.name
  policy_arn = aws_iam_policy.bedrock_claude_policy.arn
}

resource "aws_iam_instance_profile" "bedrock_instance_profile" {
  name = "HMCTSClaudeBedrockInstanceProfile"
  role = aws_iam_role.bedrock_service_role.name
}

# Policy to allow creation of long-term Bedrock API keys
resource "aws_iam_policy" "bedrock_api_key_creation" {
  name        = "BedrockAPIKeyCreationPolicy"
  description = "Allow creation of long-term Bedrock API keys"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBedrockAPIKeyUserCreation"
        Effect = "Allow"
        Action = [
          "iam:CreateUser",
          "iam:CreateAccessKey",
          "iam:PutUserPolicy",
          "iam:AttachUserPolicy",
          "iam:TagUser",
          "iam:DeleteUser",
          "iam:DeleteAccessKey",
          "iam:DeleteUserPolicy",
          "iam:DetachUserPolicy",
          "iam:ListAccessKeys",
          "iam:GetUser"
        ]
        Resource = "arn:aws:iam::*:user/BedrockAPIKey-*"
      },
      {
        Sid    = "AllowBedrockAPIKeyOperations"
        Effect = "Allow"
        Action = [
          "bedrock:CreateApiKey",
          "bedrock:ListApiKeys",
          "bedrock:DeleteApiKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the API key creation policy to the developer role
data "aws_iam_role" "developer" {
  name = "developer"
}

resource "aws_iam_role_policy_attachment" "developer_bedrock_api_keys" {
  role       = data.aws_iam_role.developer.name
  policy_arn = aws_iam_policy.bedrock_api_key_creation.arn
}

# Attach the Bedrock access policy to the developer role
resource "aws_iam_role_policy_attachment" "developer_bedrock_access" {
  role       = data.aws_iam_role.developer.name
  policy_arn = aws_iam_policy.bedrock_claude_policy.arn
}
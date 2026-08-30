# Custom role for Bedrock API key creation that bypasses the common_policy deny
resource "aws_iam_role" "bedrock_api_key_creator" {
  name = "BedrockAPIKeyCreator"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_iam_role.developer.arn
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.tags
}

# Policy that allows creating Bedrock API key users
resource "aws_iam_policy" "bedrock_api_key_creator_policy" {
  name        = "BedrockAPIKeyCreatorPolicy"
  description = "Allows creation and management of Bedrock API key users"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBedrockAPIKeyUserManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateUser",
          "iam:DeleteUser",
          "iam:GetUser",
          "iam:ListUsers",
          "iam:TagUser",
          "iam:UntagUser",
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:ListAccessKeys",
          "iam:GetAccessKeyLastUsed",
          "iam:UpdateAccessKey",
          "iam:PutUserPolicy",
          "iam:DeleteUserPolicy",
          "iam:GetUserPolicy",
          "iam:ListUserPolicies",
          "iam:AttachUserPolicy",
          "iam:DetachUserPolicy",
          "iam:ListAttachedUserPolicies",
          "iam:CreateServiceSpecificCredential",
          "iam:DeleteServiceSpecificCredential",
          "iam:ListServiceSpecificCredentials",
          "iam:ResetServiceSpecificCredential",
          "iam:UpdateServiceSpecificCredential"
        ]
        Resource = "arn:aws:iam::313941174580:user/BedrockAPIKey-*"
      },
      {
        Sid    = "AllowBedrockAPIKeyOperations"
        Effect = "Allow"
        Action = [
          "bedrock:CreateApiKey",
          "bedrock:ListApiKeys",
          "bedrock:DeleteApiKey",
          "bedrock:GetApiKey"
        ]
        Resource = [
          "arn:aws:bedrock:*:313941174580:api-key/*",
          "arn:aws:bedrock:*:313941174580:*"
        ]
      },
      {
        Sid    = "AllowListingPolicies"
        Effect = "Allow"
        Action = [
          "iam:ListPolicies"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowGettingPolicies"
        Effect = "Allow"
        Action = [
          "iam:GetPolicy",
          "iam:GetPolicyVersion"
        ]
        Resource = [
          "arn:aws:iam::313941174580:policy/*",
          "arn:aws:iam::aws:policy/*"
        ]
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "bedrock_api_key_creator_policy" {
  role       = aws_iam_role.bedrock_api_key_creator.name
  policy_arn = aws_iam_policy.bedrock_api_key_creator_policy.arn
}

# Also attach the Bedrock model access policy so this role can test the API keys
resource "aws_iam_role_policy_attachment" "bedrock_api_key_creator_bedrock_access" {
  role       = aws_iam_role.bedrock_api_key_creator.name
  policy_arn = aws_iam_policy.bedrock_claude_policy.arn
}

# Output the role ARN for easy reference
output "bedrock_api_key_creator_role_arn" {
  value       = aws_iam_role.bedrock_api_key_creator.arn
  description = "ARN of the role that can create Bedrock API keys. Assume this role to bypass the common_policy deny."
}
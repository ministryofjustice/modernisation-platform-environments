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
          "bedrock:Get*",
          "bedrock:List*"
        ],
        Resource = [
          "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-opus-4-20250514-v1:0",
          "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-sonnet-4-20250514-v1:0",
          "arn:aws:bedrock:us-east-1:*:inference-profile/us.anthropic.claude-opus-4-20250514-v1:0",
          "arn:aws:bedrock:us-east-1:*:inference-profile/us.anthropic.claude-sonnet-4-20250514-v1:0"
        ]
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
# Create IAM user
resource "aws_iam_user" "ecr_pusher" {
  name = "ecr-pusher"
}

# Create the least privilege policy for ECR access
data "aws_iam_policy_document" "ecr_policy" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]

    resources = ["*"]
  }
}

# Create the IAM policy
resource "aws_iam_policy" "ecr_policy" {
  name        = "ECRPushPolicy"
  description = "Policy to allow pushing Docker images to ECR"
  policy      = data.aws_iam_policy_document.ecr_policy.json
}

# Attach the policy to the IAM user
resource "aws_iam_user_policy_attachment" "ecr_pusher_policy_attachment" {
  user       = aws_iam_user.ecr_pusher.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}

# Create access keys for the IAM user (optional)
resource "aws_iam_access_key" "ecr_pusher_access_key" {
  user = aws_iam_user.ecr_pusher.name
}
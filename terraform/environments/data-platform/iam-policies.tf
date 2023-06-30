data "aws_iam_policy_document" "github_actions" {
  statement {
    sid    = "AllowECR"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
    ]
    resources = ["*"]
  }
}

module "github_actions_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.22.0"

  name = "${local.application_name}-gha"

  policy = data.aws_iam_policy_document.github_actions.json

  tags = local.tags
}

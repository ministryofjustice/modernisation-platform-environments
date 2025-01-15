data "aws_iam_policy_document" "analytical_platform_jml_report_ecr_repository" {
  statement {
    sid    = "LambdaECRImageRetrievalPolicy"
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy",
      "ecr:GetRepositoryPolicy"
    ]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "aws:sourceArn"
      values   = ["arn:aws:lambda:${data.aws_region.current.name}:${local.environment_management.account_ids["analytical-platform-data-production"]}:function:analytical-platform-jml-report*"]
    }
  }
}

module "analytical_platform_jml_report_ecr_repository" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/ecr/aws"
  version = "2.3.1"

  repository_name            = "analytical-platform-jml-report"
  repository_policy          = data.aws_iam_policy_document.analytical_platform_jml_report_ecr_repository.json
  repository_encryption_type = "KMS"
  repository_kms_key         = module.ecr_kms.key_arn

  create_lifecycle_policy = false

  tags = local.tags
}

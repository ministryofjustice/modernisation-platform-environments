module "analytical_platform_jml_report_ecr_repository" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/ecr/aws"
  version = "2.4.0"

  repository_name            = "analytical-platform-jml-report"
  repository_encryption_type = "KMS"
  repository_kms_key         = module.ecr_kms.key_arn
  repository_policy_statements = {
    "lambda-ecr" = {
      sid    = "LambdaECRImageRetrievalPolicy"
      effect = "Allow"
      actions = [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:SetRepositoryPolicy",
        "ecr:DeleteRepositoryPolicy",
        "ecr:GetRepositoryPolicy"
      ]
      principals = [
        {
          type        = "Service"
          identifiers = ["lambda.amazonaws.com"]
        }
      ]
      conditions = [
        {
          test     = "StringLike"
          variable = "aws:sourceArn"
          values   = ["arn:aws:lambda:${data.aws_region.current.region}:${local.environment_management.account_ids["analytical-platform-data-production"]}:function:analytical-platform-jml-report"]
        }
      ]
    }
    cross-account = {
      sid    = "CrossAccountPermission"
      effect = "Allow"
      actions = [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ]
      principals = [
        {
          type        = "AWS"
          identifiers = [local.environment_management.account_ids["analytical-platform-data-production"]]
        }
      ]
    }
  }

  create_lifecycle_policy = false

  tags = local.tags
}

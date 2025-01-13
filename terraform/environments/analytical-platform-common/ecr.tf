
data "aws_iam_policy_document" "jml_lambda_policy" {
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
      values   = ["arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["analytical-platform-data-production"]}:function:data_platform_jml_extract*)"]
    }
  }
}


# This ECR is used to store the image built by in https://github.com/ministryofjustice/analytical-platform-jml-report/releases

module "jml_ecr" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source = "terraform-aws-modules/ecr/aws"
   version = "2.3.0"

  repository_name = "analytical-platform-jml-report"

  repository_policy = data.aws_iam_policy_document.jml_lambda_policy.json

  tags = local.tags

}

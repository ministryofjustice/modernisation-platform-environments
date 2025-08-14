// TODO Scope this down... 

data "aws_iam_policy_document" "openmetadata" {
  statement {
    sid    = "openmetadata"
    effect = "Allow"
    actions = [
      "s3:*",
      "athena:*",
      "glue:*"
    ]
    resources = ["*"]
  }
}

module "openmetadata_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 6.0"

  name_prefix = "openmetadata"

  policy = data.aws_iam_policy_document.openmetadata.json

  tags = local.tags
}
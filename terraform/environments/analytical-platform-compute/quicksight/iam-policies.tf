data "aws_iam_policy_document" "quicksight_vpc_connection" {
  #checkov:skip=CKV_AWS_111:Policy suggested by AWS documentation
  #checkov:skip=CKV_AWS_356:Policy suggested by AWS documentation
  statement {
    sid    = "QuickSightVPCConnection"
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups"
    ]
    resources = ["*"]
  }
}

module "quicksight_vpc_connection_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.59.0"

  name_prefix = "quicksight-vpc-connection"

  policy = data.aws_iam_policy_document.quicksight_vpc_connection.json

  tags = local.tags
}

data "aws_iam_policy_document" "find_moj_data_quicksight_policy" {
  statement {
    effect = "Allow"
    actions = [
      "quicksight:GenerateEmbedUrlForAnonymousUser"
    ]
    resources = [
      "arn:aws:quicksight:eu-west-2:${data.aws_caller_identity.current.account_id}:namespace/default",
      "arn:aws:quicksight:eu-west-2:${data.aws_caller_identity.current.account_id}:dashboard/6898300c-69fe-4f84-b172-1784ab6bf1a0"
    ]
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "quicksight:AllowedEmbeddingDomains"

      values = [
        "https://dev.find-moj-data.service.justice.gov.uk",
        "https://preprod.find-moj-data.service.justice.gov.uk",
        "https://find-moj-data.service.justice.gov.uk"
      ]
    }
  }
}

module "find_moj_data_quicksight_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.59.0"

  name_prefix = "find-moj-data-quicksight-policy-"

  policy = data.aws_iam_policy_document.find_moj_data_quicksight_policy.json

  tags = local.tags
}

data "aws_iam_policy_document" "vpc_flow_logs" {
  statement {
    sid    = "AllowKMS"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [module.vpc_flow_logs_kms.key_arn]
  }
  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["${module.vpc_flow_logs_log_group.cloudwatch_log_group_arn}:*"]
  }
}

module "vpc_flow_logs_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.37.1"

  name_prefix = "vpc-flow-logs"

  policy = data.aws_iam_policy_document.vpc_flow_logs.json
}

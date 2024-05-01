# data "aws_iam_policy_document" "vpc_flow_logs" {
#   statement {
#     sid    = "AllowCloudWatchLogs"
#     effect = "Allow"
#     actions = [
#       "logs:CreateLogStream",
#       "logs:PutLogEvents",
#       "logs:DescribeLogGroups",
#       "logs:DescribeLogStreams",
#     ]
#     resources = [module.transfer_logs_kms.key_arn]
#   }
# }

# module "vpc_flow_logs_iam_policy" {
#   #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

#   source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
#   version = "5.37.1"

#   name_prefix = "transfer-server"

#   policy = data.aws_iam_policy_document.vpc_flow_logs.json
# }

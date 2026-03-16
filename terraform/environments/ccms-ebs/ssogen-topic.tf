# resource "aws_sns_topic" "ssogen_admin_dns_flip_topic" {
#   count           = local.is-development || local.is-test ? 1 : 0
#   name            = "ssogen-admin-dns-flip-topic"
#   delivery_policy = <<EOF
# {
#   "http": {
#     "defaultHealthyRetryPolicy": {
#       "minDelayTarget": 20,
#       "maxDelayTarget": 20,
#       "numRetries": 3,
#       "numMaxDelayRetries": 0,
#       "numNoDelayRetries": 0,
#       "numMinDelayRetries": 0,
#       "backoffFunction": "linear"
#     },
#     "disableSubscriptionOverrides": false,
#     "defaultRequestPolicy": {
#       "headerContentType": "text/plain; charset=UTF-8"
#     }
#   }
# }
# EOF

#   kms_master_key_id = aws_kms_key.ssogen_kms_key[count.index].arn
#   tags = merge(local.tags,
#     { Name = "ssogen-admin-dns-flip-topic" }
#   )
# }

# resource "aws_sns_topic_policy" "ssogen_sns_policy" {
#   count  = local.is-development || local.is-test ? 1 : 0
#   arn    = aws_sns_topic.ssogen_admin_dns_flip_topic[count.index].arn
#   policy = data.aws_iam_policy_document.ssogen_admin_dns_flip_topic_policy[count.index].json
# }

# # S3 SNS -> Lambda (Slack) instead of email
# resource "aws_sns_topic_subscription" "ssogen_admin_dns_flip_subscription" {
#   count     = local.is-development || local.is-test ? 1 : 0
#   topic_arn = aws_sns_topic.ssogen_admin_dns_flip_topic[count.index].arn
#   protocol  = "lambda"
#   endpoint  = aws_lambda_function.ssogen_lambda_dns_admin_failover[count.index].arn
# }

# data "aws_iam_policy_document" "ssogen_admin_dns_flip_topic_policy" {
#   count   = local.is-development || local.is-test ? 1 : 0
#   version = "2012-10-17"
#   statement {
#     sid    = "EventsAllowPublishSnsTopic"
#     effect = "Allow"
#     actions = [
#       "sns:Publish",
#     ]
#     resources = [
#       aws_sns_topic.ssogen_admin_dns_flip_topic[count.index].arn
#     ]
#     principals {
#       type = "Service"
#       identifiers = [
#         "cloudwatch.amazonaws.com",
#       ]
#     }
#   }

# }

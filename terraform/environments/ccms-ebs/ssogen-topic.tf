# resource "aws_sns_topic" "ssogen_admin_dns_flip_topic" {
#   name              = "ssogen-admin-dns-flip-topic"
#   delivery_policy   = <<EOF
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
#   policy            = data.aws_iam_policy_document.ssogen_admin_dns_flip_topic_policy.json
#   kms_master_key_id = aws_kms_key.ssogen_kms_key[count.index].arn
#   tags = merge(local.tags,
#     { Name = "ssogen-admin-dns-flip-topic" }
#   )
# }

# # S3 SNS -> Lambda (Slack) instead of email
# resource "aws_sns_topic_subscription" "ssogen_admin_dns_flip_subscription" {
#   topic_arn = aws_sns_topic.ssogen_admin_dns_flip_topic.arn
#   protocol  = "lambda"
#   endpoint  = aws_lambda_function.ssogen_admin_dns_flip.arn
# }

# data "aws_iam_policy_document" "ssogen_admin_dns_flip_topic_policy" {
#   version = "2012-10-17"
#   statement {
#     sid    = "EventsAllowPublishSnsTopic"
#     effect = "Allow"
#     actions = [
#       "sns:Publish",
#     ]
#     resources = [
#       aws_sns_topic.ssogen_admin_dns_flip_topic.arn
#     ]
#     principals {
#       type = "Service"
#       identifiers = [
#         "cloudwatch.amazonaws.com",
#       ]
#     }
#   }

# }
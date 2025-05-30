# # SNS topic for monitoring to send alarms to
# # resource "aws_sns_topic" "dms_alerts_topic" {
# #   name              = "delius-dms-alerts-topic"
# #   kms_master_key_id = var.account_config.kms_keys.general_shared

# #   http_success_feedback_role_arn    = aws_iam_role.sns_logging_role.arn
# #   http_success_feedback_sample_rate = 100
# #   http_failure_feedback_role_arn    = aws_iam_role.sns_logging_role.arn
# # }

# # IAM Role for Lambda
# resource "aws_iam_role" "lambda_exec" {
#   name = "dms-checker-lambda-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Action    = "sts:AssumeRole",
#       Effect    = "Allow",
#       Principal = {
#         Service = "lambda.amazonaws.com"
#       }
#     }]
#   })
# }

# # IAM Policy for Lambda (permissions to describe DMS tasks and publish to SNS)
# resource "aws_iam_role_policy" "lambda_policy" {
#   name = "dms-checker-policy"
#   role = aws_iam_role.lambda_exec.id

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = [
#           "dms:DescribeReplicationTasks"
#         ],
#         Effect   = "Allow",
#         Resource = "*"
#       },
#       {
#         Effect = "Allow",
#         Action = [
#           "cloudwatch:PutMetricData"
#         ],
#         Resource = "*"
#       },
#       {
#         Action = [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ],
#         Effect   = "Allow",
#         Resource = "*"
#       }
#     ]
#   })
# }


# # Creates a ZIP file which
# # contains a Python script to check if any DMS replication task is not running
# data "archive_file" "lambda_dms_replication_stopped_zip" {
#   type        = "zip"
#   source_file = "${path.module}/lambda/detect_stopped_replication.py"
#   output_path = "${path.module}/lambda/detect_stopped_replication.zip"
# }

# # Lambda Function to check DMS replication is not running (source in Zip archive)
# resource "aws_lambda_function" "dms_checker" {
#   function_name = "dms-task-health-checker"
#   role          = aws_iam_role.lambda_exec.arn
#   handler       = "detect_stopped_replication.lambda_handler"
#   runtime       = "python3.11"
#   timeout       = 30
#   filename      = "${path.module}/lambda/detect_stopped_replication.zip"

#   # Automatically triggers redeploy when code changes
#   source_code_hash = data.archive_file.lambda_dms_replication_stopped_zip.output_base64sha256

#   environment {
#     variables = {
#       SNS_TOPIC_ARN = aws_sns_topic.dms_alerts_topic.arn
#     }
#   }
# }

# # EventBridge Rule to Trigger Lambda Every 5 Minutes
# resource "aws_cloudwatch_event_rule" "check_dms_every_5_min" {
#   name                = "check-dms-every-5-minutes"
#   schedule_expression = "rate(5 minutes)"
# }

# resource "aws_cloudwatch_event_target" "lambda_trigger" {
#   rule      = aws_cloudwatch_event_rule.check_dms_every_5_min.name
#   target_id = "dms-task-check"
#   arn       = aws_lambda_function.dms_checker.arn
# }

# # Permission for EventBridge to invoke Lambda
# resource "aws_lambda_permission" "allow_eventbridge" {
#   statement_id  = "AllowExecutionFromEventBridge"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.dms_checker.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.check_dms_every_5_min.arn
# }

# # Raising a Cloudwatch Alarm on a DMS Replication Task Event is not directly possible using the 
# # Cloudwatch Alarm Integration in PagerDuty as the JSON payload is different.   Therefore, as
# # workaround for this we create a custom Cloudwatch Metric which is populated by the
# # DMS Health Checker Lambda Function.

# resource "aws_cloudwatch_metric_alarm" "dms_alarm" {
#   alarm_name          = "${var.env_name}-DMS-Task-Not-Running"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = 1
#   metric_name         = "DMSTaskNotRunning"
#   namespace           = "Custom/DMS"
#   period              = 300
#   statistic           = "Maximum"
#   threshold           = 1

#   alarm_description   = "Triggered when any DMS replication task is not running"
#   actions_enabled     = true
#   alarm_actions       = [aws_sns_topic.dms_alerts_topic.arn]
#   ok_actions          = [aws_sns_topic.dms_alerts_topic.arn]
# }


# # # Pager duty integration

# # # Get the map of pagerduty integration keys from the modernisation platform account
# # data "aws_secretsmanager_secret" "pagerduty_integration_keys" {
# #   provider = aws.modernisation-platform
# #   name     = "pagerduty_integration_keys"
# # }

# # data "aws_secretsmanager_secret_version" "pagerduty_integration_keys" {
# #   provider  = aws.modernisation-platform
# #   secret_id = data.aws_secretsmanager_secret.pagerduty_integration_keys.id
# # }

# # # Add a local to get the keys
# # locals {
# #   pagerduty_integration_keys = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
# #   integration_key_lookup     = var.dms_config.is-production ? "delius_oracle_prod_alarms" : "delius_oracle_nonprod_alarms"
# # }

# # # link the sns topic to the service
# # # Non-Prod alerts channel: #delius-aws-oracle-dev-alerts
# # # Prod alerts channel:     #delius-aws-oracle-prod-alerts
# # module "pagerduty_core_alerts" {
# #   #checkov:skip=CKV_TF_1
# #   depends_on = [
# #     aws_sns_topic.dms_alerts_topic
# #   ]
# #   source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
# #   sns_topics                = [aws_sns_topic.dms_alerts_topic.name]
# #   pagerduty_integration_key = local.pagerduty_integration_keys[local.integration_key_lookup]
# # }

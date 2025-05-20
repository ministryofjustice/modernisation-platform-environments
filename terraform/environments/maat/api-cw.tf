# # ######################################
# # # ECS CLOUDWATCH GROUP
# # ######################################
# resource "aws_cloudwatch_log_group" "maat_api_ecs_cw_group" {
#   name              = "${local.application_name}-api-ECS"
#   retention_in_days = 90
#   kms_key_id        = aws_kms_key.cloudwatch_logs_key.arn
#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-api-ECS"
#     },
#   )
# }
# # ECS cluster alerting
# resource "aws_cloudwatch_metric_alarm" "maat_api_ecs_cpu_over_threshold" {
#   alarm_name         = "${local.application_name}-api-ECS-CPU-high-threshold-alarm1"
#   alarm_description  = "If the CPU exceeds the predefined threshold, this alarm will trigger. Please investigate."
#   namespace          = "AWS/ECS"
#   metric_name        = "CPUUtilization"
#   statistic          = "Average"
#   period             = 60
#   evaluation_periods = 5
#   threshold          = local.application_data.accounts[local.environment].maat_api_ecs_cpu_alarm_threshold
#   treat_missing_data = "breaching"
#   alarm_actions      = [aws_sns_topic.maat_api_alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.maat_api_alerting_topic.arn]
#   unit               = "Percent"
#   dimensions = {
#     ClusterName = aws_ecs_cluster.maat_api_app_ecs_cluster.name
#     ServiceName = aws_ecs_service.maat_api_ecs_service.name
#   }
#   comparison_operator = "GreaterThanThreshold"
#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-api-ECS-CPU-high-threshold-alarm1"
#     },
#   )
# }

# resource "aws_cloudwatch_metric_alarm" "maat_api_ecs_memory_over_threshold" {
#   alarm_name         = "${local.application_name}-api-ECS-Memory-high-threshold-alarm"
#   alarm_description  = "If the memory util exceeds the predefined threshold, this alarm will trigger. Please investigate."
#   namespace          = "AWS/ECS"
#   metric_name        = "MemoryUtilization"
#   statistic          = "Average"
#   period             = 60
#   evaluation_periods = 5
#   threshold          = local.application_data.accounts[local.environment].maat_api_ecs_memory_alarm_threshold
#   treat_missing_data = "breaching"
#   alarm_actions      = [aws_sns_topic.maat_api_alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.maat_api_alerting_topic.arn]
#   unit               = "Percent"
#   dimensions = {
#     ClusterName = aws_ecs_cluster.maat_api_app_ecs_cluster.name
#     ServiceName = aws_ecs_service.maat_api_ecs_service.name
#   }
#   comparison_operator = "GreaterThanThreshold"
#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-api-ECS-Memory-high-threshold-alarm"
#     },
#   )
# }

# # Application Load Balancer Alerting
# resource "aws_cloudwatch_metric_alarm" "maat_api_target_response_time" {
#   alarm_name         = "${local.application_name}-api-alb-target-response-time-alarm"
#   alarm_description  = "The time elapsed, in seconds, after the request leaves the load balancer until a response from the target is received"
#   namespace          = "AWS/ApplicationELB"
#   metric_name        = "TargetResponseTime"
#   extended_statistic = "p99"
#   period             = 60
#   evaluation_periods = 5
#   threshold          = local.application_data.accounts[local.environment].maat_api_alb_target_response_time_threshold
#   treat_missing_data = "notBreaching"
#   alarm_actions      = [aws_sns_topic.maat_api_alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.maat_api_alerting_topic.arn]
#   dimensions = {
#     LoadBalancer = aws_lb.maat_api_ecs_lb.name
#   }
#   comparison_operator = "GreaterThanThreshold"
#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-api-alb-target-response-time-alarm"
#     },
#   )
# }

# resource "aws_cloudwatch_metric_alarm" "maat_api_target_response_time_maximum" {
#   alarm_name         = "${local.application_name}-api-alb-target-response-time-alarm-maximum"
#   alarm_description  = "The time elapsed, in seconds, after the request leaves the load balancer until a response from the target is received. Triggered if the response is longer than 60s."
#   namespace          = "AWS/ApplicationELB"
#   metric_name        = "TargetResponseTime"
#   statistic          = "Maximum"
#   period             = 60
#   evaluation_periods = 1
#   threshold          = local.application_data.accounts[local.environment].maat_api_alb_target_response_time_threshold_maximum
#   treat_missing_data = "notBreaching"
#   alarm_actions      = [aws_sns_topic.maat_api_alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.maat_api_alerting_topic.arn]
#   dimensions = {
#     LoadBalancer = aws_lb.maat_api_ecs_lb.name
#   }
#   comparison_operator = "GreaterThanThreshold"
#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-api-alb-target-response-time-alarm-maximum"
#     },
#   )
# }

# resource "aws_cloudwatch_metric_alarm" "maat_api_unhealthy_hosts" {
#   alarm_name         = "${local.application_name}-api-unhealthy-hosts-alarm"
#   alarm_description  = "The unhealthy hosts alarm triggers if your load balancer recognizes there is an unhealthy host and has been there for over 15 minutes."
#   namespace          = "AWS/ApplicationELB"
#   metric_name        = "UnHealthyHostCount"
#   statistic          = "Average"
#   period             = 60
#   evaluation_periods = 5
#   threshold          = local.application_data.accounts[local.environment].maat_api_alb_unhealthy_alarm_threshold
#   treat_missing_data = "notBreaching"
#   alarm_actions      = [aws_sns_topic.maat_api_alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.maat_api_alerting_topic.arn]
#   dimensions = {
#     LoadBalancer = aws_lb.maat_api_ecs_lb.name
#     TargetGroup  = aws_lb_target_group.maat_api_ecs_target_group.name
#   }
#   comparison_operator = "GreaterThanThreshold"
#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-api-unhealthy-hosts-alarm"
#     },
#   )
# }

# resource "aws_cloudwatch_metric_alarm" "maat_api_rejected_connection_count" {
#   alarm_name         = "${local.application_name}-api-RejectedConnectionCount-alarm"
#   alarm_description  = "There is no surge queue on ALB's. Alert triggers in ALB rejects too many requests, usually due to the backend being busy."
#   namespace          = "AWS/ApplicationELB"
#   metric_name        = "RejectedConnectionCount"
#   statistic          = "Sum"
#   period             = 60
#   evaluation_periods = 5
#   threshold          = local.application_data.accounts[local.environment].maat_api_alb_rejected_alarm_threshold
#   treat_missing_data = "notBreaching"
#   alarm_actions      = [aws_sns_topic.maat_api_alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.maat_api_alerting_topic.arn]
#   dimensions = {
#     LoadBalancer = aws_lb.maat_api_ecs_lb.name
#   }
#   comparison_operator = "GreaterThanThreshold"
#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-api-RejectedConnectionCount-alarm"
#     },
#   )
# }

# resource "aws_cloudwatch_metric_alarm" "maat_api_http_5xx_error" {
#   alarm_name         = "${local.application_name}-api-http-5xx-error-alarm"
#   alarm_description  = "This alarm will trigger if we receive 4 5XX http alerts in a 5-minute period."
#   namespace          = "AWS/ApplicationELB"
#   metric_name        = "HTTPCode_Target_5XX_Count"
#   statistic          = "Sum"
#   period             = 60
#   evaluation_periods = 5
#   threshold          = local.application_data.accounts[local.environment].maat_api_alb_target_5xx_alarm_threshold
#   treat_missing_data = "notBreaching"
#   alarm_actions      = [aws_sns_topic.maat_api_alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.maat_api_alerting_topic.arn]
#   dimensions = {
#     LoadBalancer = aws_lb.maat_api_ecs_lb.name
#   }
#   comparison_operator = "GreaterThanThreshold"
#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-api-http-5xx-error-alarm"
#     },
#   )
# }

# resource "aws_cloudwatch_metric_alarm" "maat_api_application_elb_5xx_error" {
#   alarm_name         = "${local.application_name}-api-elb-5xx-error-alarm"
#   alarm_description  = "This alarm will trigger if we receive 4 5XX elb alerts in a 5-minute period."
#   namespace          = "AWS/ApplicationELB"
#   metric_name        = "HTTPCode_ELB_5XX_Count"
#   statistic          = "Sum"
#   period             = 60
#   evaluation_periods = 5
#   threshold          = local.application_data.accounts[local.environment].maat_api_alb_5xx_alarm_threshold
#   treat_missing_data = "notBreaching"
#   alarm_actions      = [aws_sns_topic.maat_api_alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.maat_api_alerting_topic.arn]
#   dimensions = {
#     LoadBalancer = aws_lb.maat_api_ecs_lb.name
#   }
#   comparison_operator = "GreaterThanThreshold"
#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-api-elb-5xx-error-alarm"
#     },
#   )
# }

# resource "aws_cloudwatch_metric_alarm" "maat_api_http4xxError" {
#   alarm_name         = "${local.application_name}-api-http-4xx-error-alarm"
#   alarm_description  = "This alarm will trigger if we receive 4 4XX http alerts in a 5-minute period."
#   namespace          = "AWS/ApplicationELB"
#   metric_name        = "HTTPCode_Target_4XX_Count"
#   statistic          = "Sum"
#   period             = 60
#   evaluation_periods = 5
#   threshold          = local.application_data.accounts[local.environment].maat_api_alb_target_4xx_alarm_threshold
#   treat_missing_data = "notBreaching"
#   alarm_actions      = [aws_sns_topic.maat_api_alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.maat_api_alerting_topic.arn]
#   dimensions = {
#     LoadBalancer = aws_lb.maat_api_ecs_lb.name
#   }
#   comparison_operator = "GreaterThanThreshold"
#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-api-http-4xx-error-alarm"
#     },
#   )
# }

# resource "aws_cloudwatch_metric_alarm" "maat_api_application_elb_4xx_error" {
#   alarm_name         = "${local.application_name}-api-elb-4xx-error-alarm"
#   alarm_description  = "This alarm will trigger if we receive 4 4XX elb alerts in a 5-minute period."
#   namespace          = "AWS/ApplicationELB"
#   metric_name        = "HTTPCode_ELB_4XX_Count"
#   statistic          = "Sum"
#   period             = 60
#   evaluation_periods = 5
#   threshold          = local.application_data.accounts[local.environment].maat_api_alb_4xx_alarm_threshold
#   treat_missing_data = "notBreaching"
#   alarm_actions      = [aws_sns_topic.maat_api_alerting_topic.arn]
#   ok_actions         = [aws_sns_topic.maat_api_alerting_topic.arn]
#   dimensions = {
#     LoadBalancer = aws_lb.maat_api_ecs_lb.name
#   }
#   comparison_operator = "GreaterThanThreshold"
#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-api-elb-4xx-error-alarm"
#     },
#   )
# }

# # SNS topic for monitoring to send alarms to
# resource "aws_sns_topic" "maat_api_alerting_topic" {
#   name = "${local.application_name}-api-${local.environment}-alerting-topic"
#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-maat-alerting-topic"
#     }
#   )
# }

# # Pager duty integration

# # Get the map of pagerduty integration keys from the modernisation platform account
# data "aws_secretsmanager_secret" "maat_api_pagerduty_integration_keys" {
#   provider = aws.modernisation-platform
#   name     = "pagerduty_integration_keys"
# }
# data "aws_secretsmanager_secret_version" "maat_api_pagerduty_integration_keys" {
#   provider  = aws.modernisation-platform
#   secret_id = data.aws_secretsmanager_secret.maat_api_pagerduty_integration_keys.id
# }

# # Add a local to get the keys
# locals {
#   maat_api_pagerduty_integration_keys     = jsondecode(data.aws_secretsmanager_secret_version.maat_api_pagerduty_integration_keys.secret_string)
#   maat_api_pagerduty_integration_key_name = local.application_data.accounts[local.environment].maat_api_pagerduty_integration_key_name
# }

# # link the sns topic to the service

# module "maat_api_pagerduty_core_alerts" {
#   depends_on = [
#     aws_sns_topic.maat_api_alerting_topic
#   ]
#   source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
#   sns_topics                = [aws_sns_topic.maat_api_alerting_topic.name]
#   pagerduty_integration_key = local.maat_api_pagerduty_integration_keys[local.maat_api_pagerduty_integration_key_name]
# }
# ######################################
# # ECS Cluster and Service
# ######################################
# resource "aws_ecs_cluster" "maat_api_app_ecs_cluster" {
#   name = "${local.application_name}-api-ecs-cluster"

#   setting {
#     name  = "containerInsights"
#     value = "enabled"
#   }
# }

# resource "aws_ecs_service" "maat_api_ecs_service" {
#   depends_on = [aws_lb_listener.maat_api_alb_http_listener]

#   name                              = "${local.application_name}-api-ecs-service"
#   cluster                           = aws_ecs_cluster.maat_api_app_ecs_cluster.id
#   launch_type                       = "FARGATE"
#   desired_count                     = local.application_data.accounts[local.environment].maat_api_ecs_service_desired_count
#   task_definition                   = aws_ecs_task_definition.maat_api_TaskDefinition.arn
#   health_check_grace_period_seconds = 120

#   network_configuration {
#     subnets = [
#       data.aws_subnets.shared-private.ids[0],
#       data.aws_subnets.shared-private.ids[1],
#       data.aws_subnets.shared-private.ids[2],
#     ]
#     security_groups  = [aws_security_group.maat_api_ecs_security_group.id]
#     assign_public_ip = false
#   }

#   ######## ADD LB DETAILS HERE
#   load_balancer {
#     container_name   = "${local.application_name}-cd-api"
#     container_port   = 8090
#     target_group_arn = aws_lb_target_group.maat_api_ecs_target_group.arn
#   }

#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-api-ecs-service"
#     }
#   )
# }
# ######################################
# # ECS TASK DEFINITION
# ######################################
# resource "aws_ecs_task_definition" "maat_api_TaskDefinition" {
#   family                   = "${local.application_name}-api-task-definition"
#   cpu                      = local.application_data.accounts[local.environment].maat_api_ecs_cpu
#   memory                   = local.application_data.accounts[local.environment].maat_api_ecs_memory
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   execution_role_arn       = aws_iam_role.maat_api_ecs_taks_execution_role.arn
#   task_role_arn            = aws_iam_role.maat_api_ecs_taks_execution_role.arn

#   container_definitions = jsonencode([
#     {
#       name      = "${local.application_name}-cd-api",
#       cpu       = local.application_data.accounts[local.environment].maat_api_ecs_container_cpu,
#       essential = true,
#       image     = local.application_data.accounts[local.environment].maat_api_ecs_image,
#       memory    = local.application_data.accounts[local.environment].maat_api_ecs_container_memory,
#       logConfiguration = {
#         logDriver = "awslogs",
#         options = {
#           "awslogs-group"         = aws_cloudwatch_log_group.maat_api_ecs_cw_group.name,
#           "awslogs-region"        = "${data.aws_region.current.name}",
#           "awslogs-stream-prefix" = "${local.application_name}-api-app"
#         }
#       },
#       portMappings = [
#         {
#           containerPort = 8090
#           hostPort      = 8090
#           protocol      = "tcp"
#         }
#       ],
#       secrets = [
#         {
#           name      = "DATASOURCE_USERNAME",
#           valueFrom = aws_ssm_parameter.data_source_username.arn
#         },
#         {
#           name      = "DATASOURCE_PASSWORD",
#           valueFrom = aws_ssm_parameter.data_source_password.arn
#         },
#         {
#           name      = "CDA_OAUTH_CLIENT_ID",
#           valueFrom = aws_ssm_parameter.cda_client_id.arn
#         },
#         {
#           name      = "CDA_OAUTH_CLIENT_SECRET",
#           valueFrom = aws_ssm_parameter.cda_client_secret.arn
#         },
#         {
#           name      = "TOGDATA_DATASOURCE_PASSWORD",
#           valueFrom = aws_ssm_parameter.togdata_datasource_password.arn
#         }
#       ],
#       environment = [
#         {
#           name  = "DATASOURCE_URL",
#           value = local.application_data.accounts[local.environment].maat_api_ecs_env_DatasourceUrl
#         },
#         {
#           name  = "CLOUD_PLATFORM_QUEUE_REGION",
#           value = local.application_data.accounts[local.environment].maat_api_ecs_env_CloudPlatformQueueRegion
#         },
#         {
#           name  = "CREATE_LINK_QUEUE",
#           value = local.application_data.accounts[local.environment].maat_api_ecs_env_CreateLinkQueue
#         },
#         {
#           name  = "UNLINK_QUEUE",
#           value = local.application_data.accounts[local.environment].maat_api_ecs_env_UnlinkQueue
#         },
#         {
#           name  = "HEARING_RESULTED_QUEUE",
#           value = local.application_data.accounts[local.environment].maat_api_ecs_env_HearingsResultedQueue
#         },
#         {
#           name  = "CDA_OAUTH_URL",
#           value = local.application_data.accounts[local.environment].maat_api_ecs_env_CdaOauthUrl
#         },
#         {
#           name  = "CDA_BASE_URL",
#           value = local.application_data.accounts[local.environment].maat_api_ecs_env_CdaBaseUrl
#         },
#         {
#           name  = "SENTRY_ENV",
#           value = local.application_data.accounts[local.environment].maat_api_ecs_env_Environment
#         },
#         {
#           name  = "POST_MVP_ENABLED",
#           value = local.application_data.accounts[local.environment].maat_api_ecs_env_PostMvpEnabled
#         },
#         {
#           name  = "PROSECUTION_CONCLUDED_LISTENER_ENABLED",
#           value = local.application_data.accounts[local.environment].maat_api_ecs_env_ProsecutionConcludedListenerEnabled
#         },
#         {
#           name  = "PROSECUTION_CONCLUDED_SCHEDULE_ENABLED",
#           value = local.application_data.accounts[local.environment].maat_api_ecs_env_ProsecutionConcludedScheduleEnabled
#         },
#         {
#           name  = "CREATE_LINK_CP_STATUS_JOB_QUEUE",
#           value = local.application_data.accounts[local.environment].maat_api_ecs_env_CreateLinkCpStatusJobQueue
#         },
#         {
#           name  = "LAA_PROSECUTION_CONCLUDED_QUEUE",
#           value = local.application_data.accounts[local.environment].maat_api_ecs_env_LaaProsecutionConcludedQueue
#         },
#         {
#           name  = "AWS_DEFAULT_REGION",
#           value = local.application_data.accounts[local.environment].maat_api_ecs_env_AwsDefaultRegion
#         },
#         {
#           name  = "CLOUDWATCH_STEP",
#           value = local.application_data.accounts[local.environment].maat_api_ecs_env_CloudwatchStep
#         },
#         {
#           name  = "CLOUDWATCH_BATCH_SIZE",
#           value = local.application_data.accounts[local.environment].maat_api_ecs_env_CloudwatchBatchSize
#         },
#         {
#           name  = "ENABLE_CLOUDWATCH_METRICS",
#           value = local.application_data.accounts[local.environment].maat_api_ecs_env_EnableCloudwatchMetrics
#         },
#         {
#           name  = "TOGDATA_DATASOURCE_USERNAME",
#           value = local.application_data.accounts[local.environment].maat_api_ecs_env_TogDataUsername
#         }
#       ]
#     }
#   ])
# }


# ######################################
# # ECS Scaling
# ######################################
# resource "aws_appautoscaling_target" "maat_api_ecs_service_scaling_target" {
#   max_capacity       = local.application_data.accounts[local.environment].maat_api_ecs_service_max_count
#   min_capacity       = local.application_data.accounts[local.environment].maat_api_ecs_service_min_count
#   resource_id        = "service/${aws_ecs_cluster.maat_api_app_ecs_cluster.name}/${aws_ecs_service.maat_api_ecs_service.name}"
#   role_arn           = aws_iam_role.maat_api_ecs_autoscaling_role.arn
#   scalable_dimension = "ecs:service:DesiredCount"
#   service_namespace  = "ecs"
# }

# resource "aws_appautoscaling_policy" "maat_api_scaling_up_policy" {
#   name               = "${local.application_name}-api-scaling-up"
#   policy_type        = "StepScaling"
#   resource_id        = aws_appautoscaling_target.maat_api_ecs_service_scaling_target.resource_id
#   scalable_dimension = aws_appautoscaling_target.maat_api_ecs_service_scaling_target.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.maat_api_ecs_service_scaling_target.service_namespace

#   step_scaling_policy_configuration {
#     adjustment_type         = "ChangeInCapacity"
#     cooldown                = 60
#     metric_aggregation_type = "Average"

#     step_adjustment {
#       scaling_adjustment          = 1
#       metric_interval_lower_bound = 0
#     }
#   }
# }

# resource "aws_appautoscaling_policy" "maat_api_scaling_down_policy" {
#   name               = "${local.application_name}-api-scaling-down"
#   policy_type        = "StepScaling"
#   resource_id        = aws_appautoscaling_target.maat_api_ecs_service_scaling_target.resource_id
#   scalable_dimension = aws_appautoscaling_target.maat_api_ecs_service_scaling_target.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.maat_api_ecs_service_scaling_target.service_namespace

#   step_scaling_policy_configuration {
#     adjustment_type         = "ChangeInCapacity"
#     cooldown                = 60
#     metric_aggregation_type = "Average"

#     step_adjustment {
#       scaling_adjustment          = -1
#       metric_interval_lower_bound = 0
#     }
#   }
# }

# ######################################
# # CloudWatch Alarms for Scaling
# ######################################
# resource "aws_cloudwatch_metric_alarm" "maat_api_high_cpu_service_alarm" {
#   alarm_name          = "${local.application_name}-api-high-cpu-service-alarm"
#   alarm_description   = "CPUUtilization exceeding threshold. Triggers scale up"
#   actions_enabled     = true
#   namespace           = "AWS/ECS"
#   metric_name         = "CPUUtilization"
#   statistic           = "Average"
#   period              = 60
#   evaluation_periods  = 3
#   threshold           = local.application_data.accounts[local.environment].maat_api_ecs_high_cpu_scaling_threshold
#   unit                = "Percent"
#   comparison_operator = "GreaterThanThreshold"
#   alarm_actions       = [aws_appautoscaling_policy.maat_api_scaling_up_policy.arn]

#   dimensions = {
#     ClusterName = aws_ecs_cluster.maat_api_app_ecs_cluster.name
#     ServiceName = aws_ecs_service.maat_api_ecs_service.name
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "maat_api_low_cpu_service_alarm" {
#   alarm_name          = "${local.application_name}-api-low-cpu-service-alarm"
#   alarm_description   = "CPUUtilization lower than threshold. Triggers scale down"
#   actions_enabled     = true
#   namespace           = "AWS/ECS"
#   metric_name         = "CPUUtilization"
#   statistic           = "Average"
#   period              = 60
#   evaluation_periods  = 3
#   threshold           = local.application_data.accounts[local.environment].maat_api_ecs_low_cpu_scaling_threshold
#   unit                = "Percent"
#   comparison_operator = "LessThanThreshold"
#   alarm_actions       = [aws_appautoscaling_policy.maat_api_scaling_down_policy.arn]

#   dimensions = {
#     ClusterName = aws_ecs_cluster.maat_api_app_ecs_cluster.name
#     ServiceName = aws_ecs_service.maat_api_ecs_service.name
#   }
# }

# ## Memory Based Scaling
# resource "aws_cloudwatch_metric_alarm" "maat_api_high_memory_service_alarm" {
#   alarm_name          = "${local.application_name}-api-high-memory-service-alarm"
#   alarm_description   = "MemoryUtlization exceeding threshold. Triggers scale up"
#   actions_enabled     = true
#   namespace           = "AWS/ECS"
#   metric_name         = "MemoryUtilization"
#   statistic           = "Average"
#   period              = 60
#   evaluation_periods  = 3
#   threshold           = local.application_data.accounts[local.environment].maat_api_ecs_high_memory_scaling_threshold
#   unit                = "Percent"
#   comparison_operator = "GreaterThanThreshold"
#   alarm_actions       = [aws_appautoscaling_policy.maat_api_scaling_up_policy.arn]

#   dimensions = {
#     ClusterName = aws_ecs_cluster.maat_api_app_ecs_cluster.name
#     ServiceName = aws_ecs_service.maat_api_ecs_service.name
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "maat_api_low_memory_service_alarm" {
#   alarm_name          = "${local.application_name}-api-low-memory-service-alarm"
#   alarm_description   = "MemoryUtilization lower than threshold. Triggers scale down"
#   actions_enabled     = true
#   namespace           = "AWS/ECS"
#   metric_name         = "MemoryUtilization"
#   statistic           = "Average"
#   period              = 60
#   evaluation_periods  = 3
#   threshold           = local.application_data.accounts[local.environment].maat_api_ecs_low_memory_scaling_threshold
#   unit                = "Percent"
#   comparison_operator = "LessThanThreshold"
#   alarm_actions       = [aws_appautoscaling_policy.maat_api_scaling_down_policy.arn]

#   dimensions = {
#     ClusterName = aws_ecs_cluster.maat_api_app_ecs_cluster.name
#     ServiceName = aws_ecs_service.maat_api_ecs_service.name
#   }
# }
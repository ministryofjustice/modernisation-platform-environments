######################################
# ECS Role
######################################

resource "aws_iam_role" "ec2_instance_role" {
  name = "${local.application_name}-ec2-instance-role"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-instance-role"
    }
  )
  assume_role_policy = <<EOF
{
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "ec2_instance_role_policy" {
  name = "${local.application_name}-ec2-instance-role-policy"

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
            "ecs:CreateCluster",
            "ecs:DeregisterContainerInstance",
            "ecs:DiscoverPollEndpoint",
            "ecs:Poll",
            "ecs:RegisterContainerInstance",
            "ecs:StartTelemetrySession",
            "ecs:Submit*",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams",
            "ecr:*",
            "xray:PutTraceSegments",
            "xray:PutTelemetryRecords",
            "xray:GetSamplingRules",
            "xray:GetSamplingTargets",
            "xray:GetSamplingStatisticSummaries"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_instance_role_policy_attachment" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ec2_instance_role_policy.arn
}

######################################
# ECS Instance Profile
######################################

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${local.application_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-instance-profile"
    }
  )
}

######################################
# ECS Cluster 
######################################

resource "aws_ecs_cluster" "maat_app_ecs_cluster" {
  name = "${local.application_name}-ecs-cluster"

#    setting {
#     # name  = "containerInsights"
#     # value = "enabled"
#   }
}

######################################
# ECS launch config/template
######################################

resource "aws_launch_template" "ec2-launch-template" {
  name_prefix            = "${local.application_name}-ec2-launch-template"
  image_id               = local.application_data.accounts[local.environment].ami_id
  instance_type          = local.application_data.accounts[local.environment].instance_type
#   ebs_optimized          = true
#   update_default_version = true

# Need to check whether good to have
#   monitoring {
#     enabled = true
#   }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  network_interfaces {
    # associate_public_ip_address = false
    security_groups             = [aws_security_group.ecs_security_group.id]
  }

  user_data = base64encode(templatefile("maat_ec2_user_data.sh", {
    app_name = local.application_name, app_ecs_cluster = aws_ecs_cluster.maat_app_ecs_cluster.name }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(tomap({
      "Name" = "${local.application_name}-ecs-cluster"
    }), local.tags)
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(tomap({
      "Name" = "${local.application_name}-ecs-cluster"
    }), local.tags)
  }

  tags = merge(tomap({
    "Name" = "${local.application_name}-ecs-cluster-template"
  }), local.tags)
}

######################################
# ECS Scaling Group
######################################

resource "aws_autoscaling_group" "ec2_scaling_group" {
  vpc_zone_identifier   = sort(data.aws_subnets.shared-private.ids)
  name                  = "${local.application_name}-ECS"
  desired_capacity      = local.application_data.accounts[local.environment].ec2_asg_desired_capacity
  max_size              = local.application_data.accounts[local.environment].ec2_asg_max_size
  min_size              = local.application_data.accounts[local.environment].ec2_asg_min_size
#   protect_from_scale_in = true
  metrics_granularity   = "1Minute"


  launch_template {
    id      = aws_launch_template.ec2-launch-template.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = local.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

######################################
# ECS Scaling Policies
######################################

# resource "aws_appautoscaling_target" "ecs_service_scaling_target" {
#   max_capacity       = local.application_data.accounts[local.environment].ec2_max_capacity
#   min_capacity       = local.application_data.accounts[local.environment].ec2_min_capacity
#   resource_id        = "service/${aws_ecs_cluster.maat_app_ecs_cluster.id}/${aws_ecs_service.ecs_service.name}"
#   role_arn           = aws_iam_role.ec2_instance_role.arn
# #   scalable_dimension = "ecs:service:DesiredCount"
# #   service_namespace  = "ecs"
# }

resource "aws_autoscaling_policy" "maat_scaling_up_policy" {
  name               = "${local.application_name}-scaling-up"
  policy_type        = "SimpleScaling"
  adjustment_type         = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.ec2_scaling_group.name
  cooldown                = 60
  scaling_adjustment          = 1
}

resource "aws_autoscaling_policy" "maat_scaling_down_policy" {
  name               = "${local.application_name}-scaling-up"
  policy_type        = "SimpleScaling"
  adjustment_type         = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.ec2_scaling_group.name
  cooldown                = 60
  scaling_adjustment          = -1
}

######################################
# ECS Security Groups
######################################

resource "aws_security_group" "ecs_security_group" {
  name        = "${local.application_name}-ecs-security-group"
  description = "App ECS Security Group"
  vpc_id      = data.aws_vpc.shared.id
}

# resource "aws_security_group" "alb_security_group" {
#   name        = "${local.application_name}-alb-security-group"
#   description = "App ALB Security Group"
#   vpc_id      = data.aws_vpc.shared.id
# }

######################################
# ECS Security Group Rules
######################################

# resource "aws_security_group_rule" "EcsSecurityGroup1ALBports" {
#   type                     = "ingress"
#   from_port                = 32768
#   to_port                  = 61000
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.ecs_security_group.id
#   source_security_group_id = 
# }

# resource "aws_security_group_rule" "EcsSecurityGroupAllowInternalLoadBalancer" {
#   type                     = "ingress"
# #   from_port                = 
# #   to_port                  = 
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.ecs_security_group.id
#   source_security_group_id = 
# }


#####################################
# ECS CLOUDWATCH LOG GROUP
#####################################

resource "aws_cloudwatch_log_group" "ecs_cw_log_group" {
  name              = "${local.application_name}-ECS"
  retention_in_days = 90
}

######################################
# CloudWatch Alarms for CPU
######################################

resource "aws_cloudwatch_metric_alarm" "high_cpu_service_alarm" {
  alarm_name          = "${local.application_name}-high-cpu-service-alarm"
  alarm_description   = "Average CPU Reservation for the boxes in the ASG is above 74% for 1 minutes. Triggers scale up"
  actions_enabled     = true
  namespace           = "AWS/ECS"
  metric_name         = "CPUReservation"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  threshold           = local.application_data.accounts[local.environment].ec2_cpu_scaling_up_threshold
  unit                = "Percent"
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_autoscaling_policy.maat_scaling_up_policy.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.maat_app_ecs_cluster.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_service_alarm" {
  alarm_name          = "${local.application_name}-low-cpu-service-alarm"
  alarm_description   = "Average CPU Reservation for the boxes in the ASG is less than 51% for 3 minutes. Triggers scale down"
  actions_enabled     = true
  namespace           = "AWS/ECS"
  metric_name         = "CPUReservation"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  threshold           = local.application_data.accounts[local.environment].ec2_cpu_scaling_down_threshold
  unit                = "Percent"
  comparison_operator = "LessThanThreshold"
  alarm_actions       = [aws_autoscaling_policy.maat_scaling_down_policy.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.maat_app_ecs_cluster.name
  }
}

######################################
# ECS TASK DEFINITION
######################################

# resource "aws_ecs_task_definition" "XrayDaemonTaskDefinition" {
#   family                   = "${local.application_name}-app-daemon"
#   cpu                      = 32
#   memory                   = 256
# #   network_mode             = "awsvpc"
# #   requires_compatibilities = ["FARGATE"]
#   execution_role_arn       = aws_iam_role.ec2_instance_role.arn
#   task_role_arn            = aws_iam_role.ec2_instance_role.arn
#   container_definitions = jsonencode([
#     {
#       name      = "xray-daemon",
#       cpu       = 32,
#       essential = false,
#       image     = "",
#       memory    = 256,
#       log_configuration = {
#         log_driver = "awslogs",
#         options = {
#           "awslogs-group"         = aws_cloudwatch_log_group.ecs_cw_log_group.name,
#           "awslogs-region"        = "${data.aws_region.current.name}",
#           "awslogs-stream-prefix" = "${local.application_name}-app"
#         }
#       },
#       portMappings = [
#         {
#           containerPort = 2000
#           hostPort      = 2000
#           protocol      = "udp"
#         }
#       ],
#     }
#   ])
# }

# resource "aws_ecs_task_definition" "AppTaskDefinition" {
#   family                   = "${local.application_name}-app"
#   cpu                      = 992
#   memory                   = 3000

#   container_definitions = jsonencode([
#     {
#       name      = "${local.application_name}",
#       cpu       = 992,
#       essential = true,
#       image     = "",
#       memory    = 3000,
#     #   network_mode             = "awsvpc"
#     #   requires_compatibilities = ["FARGATE"]
#       execution_role_arn       = aws_iam_role.ec2_instance_role.arn
#       task_role_arn            = aws_iam_role.ec2_instance_role.arn
#       log_configuration = {
#         log_driver = "awslogs",
#         options = {
#           "awslogs-group"         = aws_cloudwatch_log_group.ecs_cw_log_group.name,
#           "awslogs-region"        = "${data.aws_region.current.name}",
#           "awslogs-stream-prefix" = "${local.application_name}-app"
#         }
#       },
#       portMappings = [
#         {
#           containerPort = 8080
#           hostPort      = 8080
#           protocol      = "tcp"
#         }
#       ],
#       environment = [
#         {
#           name  = "APP_DB_URL",
#           value = "jdbc:oracle:thin:@${pMaatDbUrl}"
#         },
#         {
#           name  = "APP_DB_USERID",
#           value = TOGDATA
#         },
#         {
#           name  = "APP_DB_PASSWORD",
#           value = APP_DB_POOL_MAX_CONNECTION
#         },
#         {
#           name  = "APP_DB_POOL_MAX_CONNECTION",
#           value = local.application_data.accountsd[local.environment].pMaatDbMaxConnectionPoolSize
#         },
#         {
#           name  = "APP_LOG_LEVEL",
#           value = local.application_data.accountsd[local.environment].pAppLogLevel
#         },
#         {
#           name  = "APP_BC_ENDPOINT",
#           value = local.application_data.accountsd[local.environment].pMaatBCEndpointURL
#         },
#         {
#           name  = "APP_BC_SERVICE_NAME",
#           value = local.application_data.accountsd[local.environment].pMaatBCServiceName
#         },
#         {
#           name  = "APP_BC_CLIENT_ORIG_ID",
#           value = local.application_data.accountsd[local.environment].pMaatBCClientOrigId
#         },
#         {
#           name  = "APP_BC_CLIENT_USER_ID",
#           value = local.application_data.accountsd[local.environment].pMaatBCClientUserId
#         },
#         {
#           name  = "APP_MLRA_LOCATION",
#           value = local.application_data.accountsd[local.environment].pMlraLocation
#         },
#         {
#           name  = "APP_CMA_BASE_URL",
#           value = local.application_data.accountsd[local.environment].pCmaBaseUrl
#         },
#         {
#           name  = "APP_CMA_CLIENT_ID",
#           value = local.application_data.accountsd[local.environment].pCmaClientId
#         },
#         {
#           name  = "APP_CMA_CLIENT_SECRET",
#           value = local.application_data.accountsd[local.environment].pCmaClientSecret
#         },
#         {
#           name  = "APP_CMA_OAUTH_SCOPE",
#           value = local.application_data.accountsd[local.environment].pCmaAuthScope
#         },
#         {
#           name  = "APP_CMA_ENDPOINT_AUTH",
#           value = local.application_data.accountsd[local.environment].pCmaEndpointAuth
#         },
#         {
#           name  = "APP_CMA_ENDPOINT_CREATE_ASSESSMENT",
#           value = local.application_data.accountsd[local.environment].pCmaEndpointMeansAssessment
#         },
#         {
#           name  = "APP_TEMP_TRIGGER_GARBAGE",
#           value = 'a random string'
#         },
#         {
#           name  = "AWS_XRAY_DAEMON_ADDRESS",
#           value = xray-daemon:2000
#         },
#         {
#           name  = "SENTRY_ENVIRONMENT",
#           value = local.application_data.accountsd[local.environment].pEnvironment
#         },
#         {
#           name  = "APP_CCP_BASE_URL",
#           value = local.application_data.accountsd[local.environment].pCcpBaseUrl
#         },
#         {
#           name  = "APP_CCP_CLIENT_ID",
#           value = local.application_data.accountsd[local.environment].pCcpClientId
#         },
#         {
#           name  = "APP_CCP_CLIENT_SECRET",
#           value = local.application_data.accountsd[local.environment].pCcpClientSecret
#         },
#         {
#           name  = "APP_CCP_OAUTH_SCOPE",
#           value = local.application_data.accounts[local.environment].pCcpAuthScope
#         },
#         {
#           name  = "APP_CCP_ENDPOINT_AUTH",
#           value = local.application_data.accounts[local.environment].pCcpEndpointAuth
#         },
#         {
#           name  = "APP_CCP_ENDPOINT_PROCEEDINGS",
#           value = local.application_data.accounts[local.environment].pCcpEndpointProceedings
#         },
#         {
#           name  = "APP_CAA_BASE_URL",
#           value = local.application_data.accounts[local.environment].pCaaBaseUrl
#         },
#         {
#           name  = "APP_CAA_CLIENT_ID",
#           value = local.application_data.accounts[local.environment].pCaaClientId
#         },
#         {
#           name  = "APP_CAA_CLIENT_SECRET",
#           value = local.application_data.accounts[local.environment].pCaaClientSecret
#         },
#         {
#           name  = "APP_CAA_OAUTH_URL",
#           value = local.application_data.accounts[local.environment].pCaaAuthUrl
#         },
#         {
#           name  = "APP_CAA_OAUTH_SCOPE",
#           value = local.application_data.accounts[local.environment].pCaaAuthScope
#         },
#         {
#           name  = "APP_CAA_ENDPOINT",
#           value = local.application_data.accounts[local.environment].pCaaEndpoint
#         },
#         {
#           name  = "APP_CCC_BASE_URL",
#           value = local.application_data.accounts[local.environment].pCccBaseUrl
#         },
#         {
#           name  = "APP_CCC_CLIENT_ID",
#           value = local.application_data.accounts[local.environment].pCccClientId
#         },
#         {
#           name  = "APP_CCC_CLIENT_SECRET",
#           value = local.application_data.accounts[local.environment].pCccClientSecret
#         },
#         {
#           name  = "APP_CCC_OAUTH_URL",
#           value = local.application_data.accounts[local.environment].pCccAuthUrl
#         },
#         {
#           name  = "APP_CCC_OAUTH_SCOPE",
#           value = local.application_data.accounts[local.environment].pCccAuthScope
#         },
#         {
#           name  = "APP_CCC_ENDPOINT",
#           value = local.application_data.accounts[local.environment].pCccEndpoint
#         },
#         {
#           name  = "APP_ORCH_BASE_URL",
#           value = local.application_data.accounts[local.environment].pOrchBaseUrl
#         },
#         {
#           name  = "APP_ORCH_CLIENT_ID",
#           value = local.application_data.accounts[local.environment].pOrchClientId
#         },
#         {
#           name  = "APP_ORCH_CLIENT_SECRET",
#           value = local.application_data.accounts[local.environment].pOrchClientSecret
#         },
#         {
#           name  = "APP_ORCH_OAUTH_URL",
#           value = local.application_data.accounts[local.environment].pOrchAuthUrl
#         },
#         {
#           name  = "APP_ORCH_OAUTH_SCOPE",
#           value = local.application_data.accounts[local.environment].pOrchAuthScope
#         },
#         {
#           name  = "APP_ORCH_ENDPOINT",
#           value = local.application_data.accounts[local.environment].pOrchEndpoint
#         },
#         {
#           name  = "APP_GOOGLE_ANALYTICS_4_TAG_ID",
#           value = local.application_data.accounts[local.environment].pGoogleAnalytics4TagId
#         }
#       ]
#     }
#   ])
# }
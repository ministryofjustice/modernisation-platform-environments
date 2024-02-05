#####################################
#
# EC2 RESOURCES
# 
#####################################

##### EC2 IAM Role

resource "aws_iam_role" "maat_ec2_instance_role" {
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

resource "aws_iam_policy" "maat_ec2_instance_role_policy" {
  name = "${local.application_name}-ec2-instance-role-policy"

  policy = jsonencode({
   Version = "2012-10-17"
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

resource "aws_iam_role_policy_attachment" "maat_ec2_instance_role_policy_attachment" {
  role       = aws_iam_role.maat_ec2_instance_role.name
  policy_arn = aws_iam_policy.maat_ec2_instance_role_policy.arn
}

resource "aws_iam_role_policy_attachment" "SSM_ec2_role_policy_attachment" {
  role       = aws_iam_role.maat_ec2_instance_role.name
  policy_arn = local.application_data.accounts[local.environment].SSM_managed_core_policy_arn
}

##### EC2 Instance Profile

resource "aws_iam_instance_profile" "maat_ec2_instance_profile" {
  name = "${local.application_name}-ec2-instance-profile"
  role = aws_iam_role.maat_ec2_instance_role.name
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-instance-profile"
    }
  )
}

#### EC2 launch config/template

resource "aws_launch_template" "maat_ec2_launch_template" {
  name_prefix            = "${local.application_name}-ec2-launch-template"
  image_id               = local.application_data.accounts[local.environment].ami_id
  instance_type          = local.application_data.accounts[local.environment].instance_type

  monitoring {
    enabled = true
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.maat_ec2_instance_profile.name
  }

  network_interfaces {
    security_groups             = [aws_security_group.maat_ecs_security_group.id]
  }

  user_data = base64encode(templatefile("maat-ec2-user-data.sh", {
    app_name = local.application_name, app_ecs_cluster = aws_ecs_cluster.maat_ecs_cluster.name }))

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

#### EC2 Scaling Group 

resource "aws_autoscaling_group" "maat_ec2_scaling_group" {
  vpc_zone_identifier   = sort(data.aws_subnets.shared-private.ids)
  name                  = "${local.application_name}-EC2-asg"
  desired_capacity      = local.application_data.accounts[local.environment].ec2_asg_desired_capacity
  max_size              = local.application_data.accounts[local.environment].ec2_asg_max_size
  min_size              = local.application_data.accounts[local.environment].ec2_asg_min_size
  metrics_granularity   = "1Minute"


  launch_template {
    id      = aws_launch_template.maat_ec2_launch_template.id
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
#### EC2 Scaling Policies 

resource "aws_autoscaling_policy" "maat_ec2_scaling_up_policy" {
  name               = "${local.application_name}-ec2-scaling-up"
  policy_type        = "SimpleScaling"
  adjustment_type         = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.maat_ec2_scaling_group.name
  cooldown                = 60
  scaling_adjustment          = 1
}

resource "aws_autoscaling_policy" "maat_ec2_scaling_down_policy" {
  name               = "${local.application_name}-ec2-scaling-down"
  policy_type        = "SimpleScaling"
  adjustment_type         = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.maat_ec2_scaling_group.name
  cooldown                = 60
  scaling_adjustment          = -1
}

#### EC2 CLOUDWATCH LOG GROUP
# Add Code here

##### EC2 CloudWatch Alarms

resource "aws_cloudwatch_metric_alarm" "maat_ec2_high_cpu_service_alarm" {
  alarm_name          = "${local.application_name}-ec2-high-cpu-service-alarm"
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
  alarm_actions       = [aws_autoscaling_policy.maat_ec2_scaling_up_policy.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.maat_app_ecs_cluster.name
  }
}

resource "aws_cloudwatch_metric_alarm" "maat_ec2_low_cpu_service_alarm" {
  alarm_name          = "${local.application_name}-ec2-low-cpu-service-alarm"
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
  alarm_actions       = [aws_autoscaling_policy.maat_ec2_scaling_down_policy.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.maat_ecs_cluster.name
  }
}


#####################################
# 
# ECS RESOURCES 
# 
#####################################

##### ECS IAM Role

resource "aws_iam_role" "maat_ecs_role" {
  name = "${local.application_name}-ecs-role"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ecs-role"
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

resource "aws_iam_policy" "maat_ecs_role_policy" {
  name = "${local.application_name}-ecs-role-policy"

  policy = jsonencode({
   Version = "2012-10-17"
   Statement = [
      {
        Effect = "Allow"
        Action = [
            "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
            "elasticloadbalancing:DeregisterTargets",
            "elasticloadbalancing:Describe*",
            "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
            "elasticloadbalancing:RegisterTargets",
            "ec2:Describe*",
            "ec2:AuthorizeSecurityGroupIngress"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "maat_ecs_role_policy_attachment" {
  role       = aws_iam_role.maat_ecs_role.name
  policy_arn = aws_iam_policy.maat_ecs_role_policy.arn
}

#### ECS Cluster 

resource "aws_ecs_cluster" "maat_ecs_cluster" {
  name = "${local.application_name}-ecs-cluster"
}

#### ECS Scaling target

resource "aws_appautoscaling_target" "maat_ecs_scaling_target" {
  max_capacity       = local.application_data.accounts[local.environment].maat_ecs_scaling_target_max
  min_capacity       = local.application_data.accounts[local.environment].maat_ecs_scaling_target_min
  resource_id        = "service/${aws_ecs_cluster.app_ecs_cluster.name}/${aws_ecs_service.maat_api_ecs_service.name}"
  role_arn           = aws_iam_role.x.arn
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

#### ECS Scaling Policies 

resource "aws_appautoscaling_policy" "maat_ecs_scaling_up_policy" {
  name               = "${local.application_name}-ecs-scaling-up"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.maat_ecs_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.maat_ecs_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.maat_ecs_scaling_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      scaling_adjustment          = 1
      metric_interval_lower_bound = 0
    }
  }
}

resource "aws_appautoscaling_policy" "maat_ecs_scaling_down_policy" {
  name               = "${local.application_name}-ecs-scaling-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.maat_ecs_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.maat_ecs_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.maat_ecs_scaling_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      scaling_adjustment          = -1
      metric_interval_lower_bound = 0
    }
  }
}

#### ECS CLOUDWATCH LOG GROUP

resource "aws_cloudwatch_log_group" "maat_ecs_cw_log_group" {
  name              = "${local.application_name}-ecs-log-group"
  retention_in_days = 90
# ASSOCIATE KEY HERE
  # kms_key_id        = aws_kms_key.cloudwatch_logs_key.arn
}

#### ECS TASK DEFINITION

resource "aws_ecs_task_definition" "maat_ecs_task_definition" {
  family                   = "${local.application_name}-ecs-task-definition"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.maat_ec2_instance_role.arn
  task_role_arn            = aws_iam_role.maat_ec2_instance_role.arn
  
  container_definitions = templatefile("maat-task-definition.json", 
    {
    docker_image_tag            = local.application_data.accounts[local.environment].docker_image_tag
    region                      = local.application_data.accounts[local.environment].region
    sentry_env                  = local.environment
    maat_orch_base_url          = local.application_data.accounts[local.environment].maat_orch_base_url
    maat_ccp_base_url           = local.application_data.accounts[local.environment].maat_ccp_base_url
    maat_orch_oauth_url         = local.application_data.accounts[local.environment].maat_orch_oauth_url
    maat_ccc_oauth_url          = local.application_data.accounts[local.environment].maat_ccc_oauth_url
    maat_cma_endpoint_auth_url  = local.application_data.accounts[local.environment].maat_cma_endpoint_auth_url
    maat_ccp_endpoint_auth_url  = local.application_data.accounts[local.environment].maat_ccp_endpoint_auth_url
    maat_db_url                 = local.application_data.accounts[local.environment].maat_db_url
    maat_ccc_base_url           = local.application_data.accounts[local.environment].maat_ccc_base_url
    maat_caa_oauth_url          = local.application_data.accounts[local.environment].maat_caa_oauth_url
    maat_bc_endpoint_url        = local.application_data.accounts[local.environment].maat_bc_endpoint_url
    maat_mlra_url               = local.application_data.accounts[local.environment].maat_mlra_url
    maat_caa_base_url           = local.application_data.accounts[local.environment].maat_caa_base_url
    maat_cma_base_url           = local.application_data.accounts[local.environment].maat_cma_base_url
    ecr_url                     = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/maat"
    maat_aws_logs_group         = local.application_data.accounts[local.environment].maat_aws_logs_group
    maat_aws_stream_prefix      = local.application_data.accounts[local.environment].maat_aws_stream_prefix
    }
  )

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-task-definition"
    }
  )
}

#### ECS Service

resource "aws_ecs_service" "maat_ecs_service" {
# Add LB names
#   depends_on = [aws_lb_listener.maat_alb_http_listener, aws_lb_listener.maat_internal_alb_https_listener]

  name                              = "${local.application_name}-ecs-service"
  cluster                           = aws_ecs_cluster.maat_ecs_cluster.id
#   launch_type                       = "FARGATE"
  desired_count                     = local.application_data.accounts[local.environment].maat_ecs_service_desired_count
  task_definition                   = aws_ecs_task_definition.maat_ecs_task_definition.arn
  iam_role                          = aws_iam_role.maat_ecs_role.arn
#   health_check_grace_period_seconds = 120
  
  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

#   network_configuration {
#     subnets = [
#       data.aws_subnets.shared-private.ids[0],
#       data.aws_subnets.shared-private.ids[1],
#       data.aws_subnets.shared-private.ids[2],
#     ]
#     security_groups  = [aws_security_group.maat_ec2_security_group.id]
#     assign_public_ip = false
#   }

#   ######## ADD LB DETAILS HERE
#   load_balancer {
#     container_name   = "${local.application_name}-cd-api"
#     container_port   = 8090
#     target_group_arn = aws_lb_target_group.maat_api_ecs_target_group.arn
#   }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ecs-service"
    }
  )
}

##### ECS CloudWatch Alarms

resource "aws_cloudwatch_metric_alarm" "high_cpu_utilisation_alarm" {
  alarm_name          = "${local.application_name}-high-cpu-utilisation-alarm"
  alarm_description   = "CPUUtilization exceeding threshold. Triggers scale up"
  actions_enabled     = true
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  threshold           = 70
  unit                = "Percent"
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_autoscaling_policy.maat_ecs_scaling_up_policy.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.maat_ecs_cluster.name
    ServiceName = aws_ecs_service.maat_ecs_service.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_utilisation_alarm" {
  alarm_name          = "${local.application_name}-low-cpu-utilisation-alarm"
  alarm_description   = "CPUUtilization lower than threshold. Triggers scale down"
  actions_enabled     = true
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  threshold           = 20
  unit                = "Percent"
  comparison_operator = "LessThanThreshold"
  alarm_actions       = [aws_autoscaling_policy.maat_ecs_scaling_down_policy.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.maat_ecs_cluster.name
    ServiceName = aws_ecs_service.maat_ecs_service.name
  }
}

#### ECS Security Groups

resource "aws_security_group" "maat_ecs_security_group" {
  name        = "${local.application_name}-ecs-security-group"
  description = "App ECS Security Group"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_security_group_rule" "alb_ingress" {
  type                     = "ingress"
  from_port                = 32768
  to_port                  = 61000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.maat_ecs_security_group.id
  source_security_group_id = aws_security_group.external_lb.id
}

resource "aws_security_group_rule" "outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.maat_ecs_security_group.id
  cidr_blocks       = ["0.0.0.0/0"]
}
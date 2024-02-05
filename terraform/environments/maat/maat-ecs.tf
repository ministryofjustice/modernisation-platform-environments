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
    "Version": "2008-10-17",
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

resource "aws_iam_role_policy_attachment" "ec2_instance_role_policy_attachment" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ec2_instance_role_policy.arn
}

resource "aws_iam_role_policy_attachment" "SSM_managed_core_policy_attachment" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = local.application_data.accounts[local.environment].SSM_managed_core_policy_arn
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
}

######################################
# ECS launch config/template
######################################

resource "aws_launch_template" "ec2-launch-template" {
  name_prefix   = "${local.application_name}-ec2-launch-template"
  image_id      = local.application_data.accounts[local.environment].ami_id
  instance_type = local.application_data.accounts[local.environment].instance_type

  monitoring {
    enabled = true
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  network_interfaces {
    security_groups = [aws_security_group.ecs_security_group.id]
  }

  user_data = base64encode(templatefile("maat-ec2-user-data.sh", {
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
  vpc_zone_identifier = sort(data.aws_subnets.shared-private.ids)
  name                = "${local.application_name}-ECS"
  desired_capacity    = local.application_data.accounts[local.environment].ec2_asg_desired_capacity
  max_size            = local.application_data.accounts[local.environment].ec2_asg_max_size
  min_size            = local.application_data.accounts[local.environment].ec2_asg_min_size
  metrics_granularity = "1Minute"


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

resource "aws_autoscaling_policy" "maat_scaling_up_policy" {
  name                   = "${local.application_name}-scaling-up"
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.ec2_scaling_group.name
  cooldown               = 60
  scaling_adjustment     = 1
}

resource "aws_autoscaling_policy" "maat_scaling_down_policy" {
  name                   = "${local.application_name}-scaling-down"
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.ec2_scaling_group.name
  cooldown               = 60
  scaling_adjustment     = -1
}

######################################
# ECS Security Groups
######################################

resource "aws_security_group" "ecs_security_group" {
  name        = "${local.application_name}-ecs-security-group"
  description = "App ECS Security Group"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_security_group_rule" "alb_ingress" {
  type                     = "ingress"
  from_port                = 32768
  to_port                  = 61000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_security_group.id
  source_security_group_id = aws_security_group.external_lb.id
}

resource "aws_security_group_rule" "outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.ecs_security_group.id
  cidr_blocks       = ["0.0.0.0/0"]
}

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

# #####################################
# ECS TASK DEFINITION
# #####################################

resource "aws_ecs_task_definition" "maat_task_definition" {
  family                   = "${local.application_name}-task-definition"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.ec2_instance_role.arn
  task_role_arn            = aws_iam_role.ec2_instance_role.arn

  container_definitions = templatefile("maat-task-definition.json",
    {
      docker_image_tag           = local.application_data.accounts[local.environment].docker_image_tag
      region                     = local.application_data.accounts[local.environment].region
      sentry_env                 = local.environment
      maat_orch_base_url         = local.application_data.accounts[local.environment].maat_orch_base_url
      maat_ccp_base_url          = local.application_data.accounts[local.environment].maat_ccp_base_url
      maat_orch_oauth_url        = local.application_data.accounts[local.environment].maat_orch_oauth_url
      maat_ccc_oauth_url         = local.application_data.accounts[local.environment].maat_ccc_oauth_url
      maat_cma_endpoint_auth_url = local.application_data.accounts[local.environment].maat_cma_endpoint_auth_url
      maat_ccp_endpoint_auth_url = local.application_data.accounts[local.environment].maat_ccp_endpoint_auth_url
      maat_db_url                = local.application_data.accounts[local.environment].maat_db_url
      maat_ccc_base_url          = local.application_data.accounts[local.environment].maat_ccc_base_url
      maat_caa_oauth_url         = local.application_data.accounts[local.environment].maat_caa_oauth_url
      maat_bc_endpoint_url       = local.application_data.accounts[local.environment].maat_bc_endpoint_url
      maat_mlra_url              = local.application_data.accounts[local.environment].maat_mlra_url
      maat_caa_base_url          = local.application_data.accounts[local.environment].maat_caa_base_url
      maat_cma_base_url          = local.application_data.accounts[local.environment].maat_cma_base_url
      ecr_url                    = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/maat"
      maat_aws_logs_group        = local.application_data.accounts[local.environment].maat_aws_logs_group
      maat_aws_stream_prefix     = local.application_data.accounts[local.environment].maat_aws_stream_prefix
    }
  )

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-task-definition"
    }
  )
}
data "aws_vpc" "shared" {
  tags = {
    "Name" = var.vpc_all
  }
}

data "aws_subnet_ids" "shared-private" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.subnet_set_name}-private*"
  }
}

# # data "aws_ecr_image" "service_image" {
# #   repository_name = var.app_name
# #   image_tag       = var.container_version
# # }
# data "aws_db_instance" "database" {
#   db_instance_identifier = var.app_name
# }
data "aws_security_group" "loadbalancer" {
  name = var.app_name
}
data "aws_lb_target_group" "target_group" {
  name = var.app_name
}
# data "aws_lb" "selected" {
#   name = var.app_name
# }
# data "aws_lb_listener" "listener" {
#   load_balancer_arn = data.aws_lb.selected.arn
#   port              = var.server_port
# }
#

resource "aws_iam_service_linked_role" "ecs" {
  aws_service_name = "ecs.amazonaws.com"
}

resource "aws_autoscaling_group" "cluster-scaling-group" {
  vpc_zone_identifier = sort(data.aws_subnet_ids.shared-private.ids)
  desired_capacity    = var.ec2_desired_capacity
  max_size            = var.ec2_max_size
  min_size            = var.ec2_min_size

  launch_template {
    id      = aws_launch_template.ec2-launch-template.id
    version = "$Latest"
  }
}

# EC2 Security Group
# Controls access to the EC2 instances

resource "aws_security_group" "cluster_ec2" {
  name        = "${var.app_name}-cluster-ec2-security-group"
  description = "controls access to the cluster ec2 instance"
  vpc_id      = data.aws_vpc.shared.id

  # ingress {
  #   protocol  = "tcp"
  #   from_port = 7001
  #   to_port   = 7001
  #   cidr_blocks = concat(
  #     var.cidr_access
  #   )
  # }

  ingress {
    protocol  = "tcp"
    from_port = 32768
    to_port   = 65535
    security_groups = [
      data.aws_security_group.loadbalancer.id
    ]
  }

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = var.tags_common
}

# EC2 launch template - settings to use for new EC2s added to the group
# Note - when updating this you will need to manually terminate the EC2s
# so that the autoscaling group creates new ones using the new launch template

resource "aws_launch_template" "ec2-launch-template" {
  name_prefix   = var.app_name
  image_id      = var.ami_image_id
  instance_type = var.instance_type
  key_name      = var.key_name
  ebs_optimized = true

  monitoring {
    enabled = true
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.cluster_ec2.id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = 30
      volume_type           = "gp2"
      iops                  = 0
    }
  }

  user_data = var.user_data

  tag_specifications {
    resource_type = "instance"
    tags = merge(tomap({
      "Name" = "${var.app_name}-ecs-cluster"
    }), var.tags_common)
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(tomap({
      "Name" = "${var.app_name}-ecs-cluster"
    }), var.tags_common)
  }

  tags = merge(tomap({
    "Name" = "${var.app_name}-ecs-cluster-template"
  }), var.tags_common)
}

# IAM Role, policy and instance profile (to attach the role to the EC2)

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.app_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_iam_role" "ec2_instance_role" {
  name = "${var.app_name}-ec2-instance-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "ec2_instance_policy" {
  name = "${var.app_name}-ec2-instance-policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeTags",
                "ecs:CreateCluster",
                "ecs:DeregisterContainerInstance",
                "ecs:DiscoverPollEndpoint",
                "ecs:Poll",
                "ecs:RegisterContainerInstance",
                "ecs:StartTelemetrySession",
                "ecs:UpdateContainerInstancesState",
                "ecs:Submit*",
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_ec2_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ec2_instance_policy.arn
}
//ECS cluster

resource "aws_ecs_cluster" "ecs_cluster" {
  name               = var.app_name
  capacity_providers = [aws_ecs_capacity_provider.capacity_provider.name]
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family             = "${var.app_name}-task-definition"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = [
    "EC2",
  ]
  cpu    = var.container_cpu
  memory = var.container_memory

  volume {
    name = "upload_volume"
    # efs_volume_configuration {
    #   file_system_id = aws_efs_file_system.storage.id
    # }
  }

  container_definitions = var.task_definition

  tags = var.tags_common
}

resource "aws_ecs_service" "ecs_service" {
  name            = var.app_name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = var.app_count
  launch_type     = "EC2"

  health_check_grace_period_seconds = 300

  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  load_balancer {
    target_group_arn = data.aws_lb_target_group.target_group.id
    container_name   = var.app_name
    container_port   = var.server_port
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role,
  ]

  tags = var.tags_common
}

resource "aws_ecs_capacity_provider" "capacity_provider" {
  name = var.app_name

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.cluster-scaling-group.arn
  }

  tags = var.tags_common
}
# ECS task execution role data
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
data "aws_iam_policy_document" "ecs_task_execution_role" {
  version = "2012-10-17"
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com",
      ]
    }
  }
}

# ECS task execution role
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = var.app_name
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json
  tags               = var.tags_common
}

# ECS task execution role policy attachment
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_role_policy_attachment" "ecs_task_secrets_manager" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

##### ECS autoscaling ##########

resource "aws_appautoscaling_target" "scaling_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 3
}

# Automatically scale capacity up by one
resource "aws_appautoscaling_policy" "scaling_policy_up" {
  name               = "${var.app_name}-scale-up-policy"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [
    aws_appautoscaling_target.scaling_target,
  ]
}

# Automatically scale capacity down by one
resource "aws_appautoscaling_policy" "scaling_policy_down" {
  name               = "${var.app_name}-scale-down-policy"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [
    aws_appautoscaling_target.scaling_target,
  ]
}

# # CloudWatch alarm that triggers the autoscaling up policy
# resource "aws_cloudwatch_metric_alarm" "alarm_service_cpu_high" {
#   alarm_name          = "${var.app_name}-cpu-utilization-high"
#   alarm_description   = "${var.account_name} | cpu utilization high, this alarm will trigger the scale up policy."
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = "3"
#   datapoints_to_alarm = "3"
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/ECS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = "85"
#
#   dimensions = {
#     ClusterName = aws_ecs_cluster.ecs_cluster.name
#     ServiceName = aws_ecs_service.ecs_service.name
#   }
#
#   # alarm_actions = [
#   #   aws_appautoscaling_policy.scaling_policy_up.arn, local.monitoring_sns_topic
#   # ]
#   # ok_actions = [local.monitoring_sns_topic]
#
#   tags = var.tags_common
# }
#
# # CloudWatch alarm that triggers the autoscaling down policy
# resource "aws_cloudwatch_metric_alarm" "alarm_service_cpu_low" {
#   alarm_name          = "${var.app_name}-cpu-utilization-low"
#   alarm_description   = "${var.account_name} | cpu utilization low, this alarm will trigger the scale down policy."
#   comparison_operator = "LessThanOrEqualToThreshold"
#   evaluation_periods  = "3"
#   datapoints_to_alarm = "3"
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/ECS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = "10"
#
#   dimensions = {
#     ClusterName = aws_ecs_cluster.ecs_cluster.name
#     ServiceName = aws_ecs_service.ecs_service.name
#   }
#
#   alarm_actions = [aws_appautoscaling_policy.scaling_policy_down.arn]
#
#   tags = var.tags_common
# }
#
# # ECS Alerts
# # See autoscaling files for CPU alerts
# resource "aws_cloudwatch_metric_alarm" "Ecs_Memory_Over_Threshold" {
#   alarm_name          = "${var.app_name}-ECS-Memory-high-threshold-alarm"
#   alarm_description   = "${var.account_name} | ECS average memory usage is above 75% please investigate"
#   comparison_operator = "GreaterThanThreshold"
#   metric_name         = "MemoryUtilization"
#   statistic           = "Average"
#   namespace           = "AWS/ECS"
#   period              = "60"
#   evaluation_periods  = "5"
#   threshold           = "75"
#   treat_missing_data  = "breaching"
#   dimensions = {
#     ClusterName = aws_ecs_cluster.ecs_cluster.name
#     ServiceName = aws_ecs_service.ecs_service.name
#   }
#
#   # alarm_actions = [local.monitoring_sns_topic]
#   # ok_actions    = [local.monitoring_sns_topic]
#
#   tags = var.tags_common
# }
#
#
# # EC2 / Autoscaling group alarms
# resource "aws_cloudwatch_metric_alarm" "EC2_CPU_over_Threshold" {
#   alarm_name          = "${var.app_name}-EC2-CPU-high-threshold-alarm"
#   alarm_description   = "${var.account_name} | EC2 CPU utilisation is above 85% please investigate, runbook"
#   comparison_operator = "GreaterThanThreshold"
#   metric_name         = "CPUUtilization"
#   statistic           = "Average"
#   namespace           = "AWS/EC2"
#   period              = "60"
#   evaluation_periods  = "5"
#   threshold           = "85"
#   treat_missing_data  = "breaching"
#   dimensions = {
#     AutoScalingGroupName = aws_autoscaling_group.cluster-scaling-group.name
#   }
#
#   # alarm_actions = [local.monitoring_sns_topic]
#   # ok_actions    = [local.monitoring_sns_topic]
#
#   tags = var.tags_common
# }
#
# resource "aws_cloudwatch_metric_alarm" "Status_Check_Failure" {
#   alarm_name          = "${var.app_name}-status-check-failure-alarm"
#   alarm_description   = "${var.account_name} | EC2 instance has failed a status check, please investigate, runbook"
#   comparison_operator = "GreaterThanThreshold"
#   metric_name         = "StatusCheckFailed"
#   statistic           = "Average"
#   namespace           = "AWS/EC2"
#   period              = "60"
#   evaluation_periods  = "5"
#   threshold           = "1"
#   treat_missing_data  = "breaching"
#   dimensions = {
#     AutoScalingGroupName = aws_autoscaling_group.cluster-scaling-group.name
#   }
#
#   # alarm_actions = [local.monitoring_sns_topic]
#   # ok_actions    = [local.monitoring_sns_topic]
#
#   tags = var.tags_common
# }
# Set up CloudWatch group and log stream and retain logs for 30 days
resource "aws_cloudwatch_log_group" "cloudwatch_group" {
  name              = "${var.app_name}-ecs"
  retention_in_days = 30
  tags              = var.tags_common
}

resource "aws_cloudwatch_log_stream" "cloudwatch_stream" {
  name           = "${var.app_name}-log-stream"
  log_group_name = aws_cloudwatch_log_group.cloudwatch_group.name
}

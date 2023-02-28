data "aws_vpc" "shared" {
  tags = {
    "Name" = var.vpc_all
  }
}

data "aws_ecs_task_definition" "task_definition" {
  task_definition = "${var.app_name}-task-definition"
  depends_on      = [aws_ecs_task_definition.windows_ecs_task_definition, aws_ecs_task_definition.linux_ecs_task_definition]
}

data "aws_subnets" "shared-private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${var.subnet_set_name}-private*"
  }
}

resource "aws_autoscaling_group" "cluster-scaling-group" {
  vpc_zone_identifier = sort(data.aws_subnets.shared-private.ids)
  name                = "${var.app_name}-cluster-scaling-group"
  desired_capacity    = var.ec2_desired_capacity
  max_size            = var.ec2_max_size
  min_size            = var.ec2_min_size

  launch_template {
    id      = aws_launch_template.ec2-launch-template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.app_name}-cluster-scaling-group"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags_common

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# EC2 Security Group
# Controls access to the EC2 instances

resource "aws_security_group" "cluster_ec2" {
  #checkov:skip=CKV_AWS_23
  name        = "${var.app_name}-cluster-ec2-security-group"
  description = "controls access to the cluster ec2 instance"
  vpc_id      = data.aws_vpc.shared.id

  dynamic "ingress" {
    for_each = var.ec2_ingress_rules
    content {
      description     = lookup(ingress.value, "description", null)
      from_port       = lookup(ingress.value, "from_port", null)
      to_port         = lookup(ingress.value, "to_port", null)
      protocol        = lookup(ingress.value, "protocol", null)
      cidr_blocks     = lookup(ingress.value, "cidr_blocks", null)
      security_groups = lookup(ingress.value, "security_groups", null)
    }
  }
  dynamic "egress" {
    for_each = var.ec2_egress_rules
    content {
      description     = lookup(egress.value, "description", null)
      from_port       = lookup(egress.value, "from_port", null)
      to_port         = lookup(egress.value, "to_port", null)
      protocol        = lookup(egress.value, "protocol", null)
      cidr_blocks     = lookup(egress.value, "cidr_blocks", null)
      security_groups = lookup(egress.value, "security_groups", null)
    }
  }

  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-cluster-ec2-security-group"
    }
  )
}

# EC2 launch template - settings to use for new EC2s added to the group
# Note - when updating this you will need to manually terminate the EC2s
# so that the autoscaling group creates new ones using the new launch template

resource "aws_launch_template" "ec2-launch-template" {
  name_prefix            = "${var.app_name}-ec2-launch-template"
  image_id               = var.ami_image_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  ebs_optimized          = true
  update_default_version = true

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = "2"
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
  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-ec2-instance-profile"
    }
  )
}

resource "aws_iam_role" "ec2_instance_role" {
  name = "${var.app_name}-ec2-instance-role"
  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-ec2-instance-role"
    }
  )
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

resource "aws_iam_policy" "ec2_instance_policy" { #tfsec:ignore:aws-iam-no-policy-wildcards
  name = "${var.app_name}-ec2-instance-policy"
  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-ec2-instance-policy"
    }
  )
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeTags",
                "ec2:DescribeInstances",
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
                "ecr:*",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:CreateLogGroup",
                "logs:DescribeLogStreams",
                "s3:ListBucket",
                "s3:*Object*",
                "kms:Decrypt",
                "kms:Encrypt",
                "kms:GenerateDataKey",
                "kms:ReEncrypt",
                "kms:GenerateDataKey",
                "kms:DescribeKey",
                "xray:PutTraceSegments",
                "xray:PutTelemetryRecords",
                "xray:GetSamplingRules",
                "xray:GetSamplingTargets",
                "xray:GetSamplingStatisticSummaries",
                "xray:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "CloudWatchAgentServerPolicy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "attach_ec2_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ec2_instance_policy.arn
}


# EC2 Target Tracking scaling

resource "aws_autoscaling_policy" "ec2-cpu-scaling-target" {
  name                      = "ec2-cpu-scaling-target"
  policy_type               = "TargetTrackingScaling"
  autoscaling_group_name    = aws_autoscaling_group.cluster-scaling-group.name
  estimated_instance_warmup = 200
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.ec2_scaling_cpu_threshold
  }
}

resource "aws_autoscaling_policy" "ec2-mem-scaling-target" {
  name                      = "ec2-mem-scaling-target"
  policy_type               = "TargetTrackingScaling"
  autoscaling_group_name    = aws_autoscaling_group.cluster-scaling-group.name
  estimated_instance_warmup = 200
  target_tracking_configuration {
    target_value     = var.ec2_scaling_mem_threshold
    disable_scale_in = false
    customized_metric_specification {
      metric_name = "MemoryUtilization"
      namespace   = "AWS/ECS"
      statistic   = "Average"
      metric_dimension {
        name  = "ClusterName"
        value = var.app_name
      }
    }
  }
}



//ECS cluster

resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.app_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = merge(
    var.tags_common,
    {
      Name = var.app_name
    }
  )
}

resource "aws_ecs_cluster_capacity_providers" "ecs_cluster" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name
}

resource "aws_ecs_task_definition" "windows_ecs_task_definition" {
  family             = "${var.app_name}-task-definition"
  count              = var.container_instance_type == "windows" ? 1 : 0
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = [
    "EC2",
  ]

  volume {
    name = var.task_definition_volume
  }

  container_definitions = var.task_definition

  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-windows-task-definition"
    }
  )
}

resource "aws_ecs_task_definition" "linux_ecs_task_definition" {
  family             = "${var.app_name}-task-definition"
  network_mode       = var.network_mode
  count              = var.container_instance_type == "linux" ? 1 : 0
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = [
    "EC2",
  ]

  volume {
    name = var.task_definition_volume
  }

  container_definitions = var.task_definition

  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-linux-task-definition"
    }
  )
}

resource "aws_ecs_service" "ecs_service" {
  name            = "${var.app_name}-ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = data.aws_ecs_task_definition.task_definition.id
  desired_count   = var.app_count
  launch_type     = "EC2"

  health_check_grace_period_seconds = 300

  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  load_balancer {
    target_group_arn = var.lb_tg_arn
    container_name   = var.app_name
    container_port   = var.server_port
  }

  # TODO What are these dependencies for and can remove the depends_on here?
  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role, aws_ecs_task_definition.windows_ecs_task_definition, aws_ecs_task_definition.linux_ecs_task_definition, aws_cloudwatch_log_group.cloudwatch_group
  ]

  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-ecs-service"
    }
  )
}

resource "aws_ecs_capacity_provider" "capacity_provider" {
  name = "${var.app_name}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.cluster-scaling-group.arn
  }

  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-capacity-provider"
    }
  )
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

resource "aws_iam_policy" "ecs_task_execution_s3_policy" { #tfsec:ignore:aws-iam-no-policy-wildcards
  name = "${var.app_name}-ecs-task-execution-s3-policy"
  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-ecs-task-execution-s3-policy"
    }
  )
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:*Object*",
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:ReEncrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets",
        "ec2:Describe*",
        "ec2:AuthorizeSecurityGroupIngress"
      ],
      "Resource": ["*"]
    }
  ]
}
EOF
}


# ECS task execution role
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.app_name}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json
  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-ecs-task-execution-role"
    }
  )
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
resource "aws_iam_role_policy_attachment" "ecs_task_s3_access" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_s3_policy.arn
}


# Set up CloudWatch group and log stream and retain logs for 30 days
resource "aws_cloudwatch_log_group" "cloudwatch_group" {
  #checkov:skip=CKV_AWS_158:Temporarily skip KMS encryption check while logging solution is being updated
  name              = "${var.app_name}-ecs-log-group"
  retention_in_days = 30
  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-ecs-log-group"
    }
  )
}

resource "aws_cloudwatch_log_stream" "cloudwatch_stream" {
  name           = "${var.app_name}-log-stream"
  log_group_name = aws_cloudwatch_log_group.cloudwatch_group.name
}



# Added to support target tracking scaling_adjustment

# resource "aws_iam_role" "ecs-autoscale-role" {
#   name = "ecs-scale-application"
#
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "application-autoscaling.amazonaws.com"
#       },
#       "Effect": "Allow"
#     }
#   ]
# }
# EOF
# }


# ECS cluster scaling

# resource "aws_iam_role_policy_attachment" "ecs-autoscale" {
#   role       = aws_iam_role.ecs-autoscale-role.id
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
# }

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.appscaling_max_capacity
  min_capacity       = var.appscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  # role_arn           = aws_iam_role.ecs-autoscale-role.arn
}

resource "aws_appautoscaling_policy" "ecs_target_cpu" {
  name               = "application-scaling-policy-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.ecs_scaling_cpu_threshold
  }
  # depends_on = [aws_appautoscaling_target.ecs_target]
}

resource "aws_appautoscaling_policy" "ecs_target_memory" {
  name               = "application-scaling-policy-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = var.ecs_scaling_mem_threshold
  }
  # depends_on = [aws_appautoscaling_target.ecs_target]
}

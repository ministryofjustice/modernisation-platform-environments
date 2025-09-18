#####################################
#
# EC2 RESOURCES (from infra stack)
#
#####################################

##### EC2 IAM Role ---------

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
    "Version": "2008-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow"
        },
        {
            "Effect": "Allow",
            "Principal": {
              "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
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
          "s3:ListBucket",
          "s3:*Object*",
          "s3:GetObjectACL",
          "s3:putObjectACL",
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
          "xray:GetSamplingStatisticSummaries"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "maat_ec2_instance_role_policy_attachment" {
  role       = aws_iam_role.maat_ec2_instance_role.name
  policy_arn = aws_iam_policy.maat_ec2_instance_role_policy.arn
}

# resource "aws_iam_role_policy_attachment" "SSM_ec2_role_policy_attachment" {
#   role       = aws_iam_role.maat_ec2_instance_role.name
#   policy_arn = local.application_data.accounts[local.environment].SSM_managed_core_policy_arn
# }

##### EC2 Instance Profile ------

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

#### ECS Cluster -----

resource "aws_ecs_cluster" "maat_ecs_cluster" {
  name = "${local.application_name}-ecs-cluster"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-instance-profile"
    }
  )
}

# always use the recommended ECS optimized linux 2 base image; used to obtain its AMI ID
data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

# if the AMI is used elsewhere it can be obtained here
output "ami_id" {
  value     = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  sensitive = true
}

##### EC2 launch config/template -----

resource "aws_launch_template" "maat_ec2_launch_template" {
  name_prefix   = "${local.application_name}-ec2-launch-template"
  image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  instance_type = local.application_data.accounts[local.environment].instance_type

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = "2"
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.maat_ec2_instance_profile.name
  }

  network_interfaces {
    security_groups = [aws_security_group.maat_ecs_security_group.id]
  }

  user_data = base64encode(templatefile("maat-ec2-user-data.sh", {
    maat_ec2_log_group = local.application_data.accounts[local.environment].maat_ec2_log_group,
    app_ecs_cluster    = aws_ecs_cluster.maat_ecs_cluster.name,
    environment        = local.environment,
    xdr_dir            = "/tmp/cortex-agent",
    xdr_tar            = "/tmp/cortex-agent.tar.gz",
    xdr_tags           = local.xdr_tags
  }))

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

#### EC2 Scaling Group  -----

resource "aws_autoscaling_group" "maat_ec2_scaling_group" {
  vpc_zone_identifier = sort(data.aws_subnets.shared-private.ids)
  name                = "${local.application_name}-EC2-asg"
  desired_capacity    = local.application_data.accounts[local.environment].maat_ec2_asg_desired_capacity
  max_size            = local.application_data.accounts[local.environment].maat_ec2_asg_max_size
  min_size            = local.application_data.accounts[local.environment].maat_ec2_asg_min_size
  metrics_granularity = "1Minute"


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
  name                   = "${local.application_name}-ec2-scaling-up"
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.maat_ec2_scaling_group.name
  cooldown               = 60
  scaling_adjustment     = 1
}

resource "aws_autoscaling_policy" "maat_ec2_scaling_down_policy" {
  name                   = "${local.application_name}-ec2-scaling-down"
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.maat_ec2_scaling_group.name
  cooldown               = 60
  scaling_adjustment     = -1
}

#### ECS Security Groups -----

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

resource "aws_security_group_rule" "maat_sg_rule_int_lb_to_ecs" {
  security_group_id        = aws_security_group.maat_ecs_security_group.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.maat_int_lb_sg.id
}

resource "aws_security_group_rule" "maat_sg_rule_outbound" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "This rule is needed for the ECS agent to reach the ECS API endpoints"
  security_group_id = aws_security_group.maat_ecs_security_group.id
}

resource "aws_security_group_rule" "maat_to_maatdb_sg_rule_outbound" {
  type                     = "egress"
  from_port                = 1521
  to_port                  = 1521
  protocol                 = "tcp"
  description              = "This rule is needed for the ECS agent to reach the ECS API endpoints"
  security_group_id        = aws_security_group.maat_ecs_security_group.id
  source_security_group_id = local.application_data.accounts[local.environment].maatdb_rds_sec_group_id
}

#### EC2 CLOUDWATCH LOG GROUP & Key ------

resource "aws_kms_key" "maat_ec2_cloudwatch_log_key" {
  description         = "KMS key to be used for encrypting the CloudWatch logs in the Log Groups"
  enable_key_rotation = true
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-key"
    }
  )
}

resource "aws_kms_key_policy" "maat_cloudwatch_logs_policy_ec2" {
  key_id = aws_kms_key.maat_ec2_cloudwatch_log_key.id
  policy = jsonencode({
    Id = "key-default-1"
    Statement = [
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.env_account_id}:root"
        }

        Resource = "*"
        Sid      = "Enable IAM User Permissions"
      },
      {
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Effect = "Allow"
        Principal = {
          Service = "logs.eu-west-2.amazonaws.com"
        }
        Resource = "*"
        Sid      = "Enable log service Permissions"
      }
    ]
    Version = "2012-10-17"
  })
}

resource "aws_cloudwatch_log_group" "ec2_cloudwatch_log_group" {
  name              = local.application_data.accounts[local.environment].maat_ec2_log_group
  retention_in_days = 365
  kms_key_id        = aws_kms_key.maat_ec2_cloudwatch_log_key.arn
}

##### EC2 CloudWatch Alarms

resource "aws_cloudwatch_metric_alarm" "maat_ec2_high_cpu_alarm" {
  alarm_name          = "${local.application_name}-ec2-high-cpu-alarm"
  alarm_description   = "Average CPU Reservation for the boxes in the ASG is above 74% for 1 minutes. Triggers scale up"
  actions_enabled     = true
  namespace           = "AWS/ECS"
  metric_name         = "CPUReservation"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  threshold           = local.application_data.accounts[local.environment].maat_ec2_cpu_scaling_up_threshold
  unit                = "Percent"
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_autoscaling_policy.maat_ec2_scaling_up_policy.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.maat_ecs_cluster.name
  }
}

resource "aws_cloudwatch_metric_alarm" "maat_ec2_low_cpu_alarm" {
  alarm_name          = "${local.application_name}-ec2-low-cpu-alarm"
  alarm_description   = "Average CPU Reservation for the boxes in the ASG is less than 51% for 3 minutes. Triggers scale down"
  actions_enabled     = true
  namespace           = "AWS/ECS"
  metric_name         = "CPUReservation"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  threshold           = local.application_data.accounts[local.environment].maat_ec2_cpu_scaling_down_threshold
  unit                = "Percent"
  comparison_operator = "LessThanThreshold"
  alarm_actions       = [aws_autoscaling_policy.maat_ec2_scaling_down_policy.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.maat_ecs_cluster.name
  }
}

#####################################
#
# ECS RESOURCES (from app stack)
#
#####################################

##### ECS Service Role -----

resource "aws_iam_role" "maat_ecs_service_role" {
  name = "${local.application_name}-ecs-service-role"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ecs-service-role"
    }
  )
  assume_role_policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ecs.amazonaws.com"
            },
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "maat_ecs_service_role_policy" {
  name = "${local.application_name}-ecs-service-role-policy"

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
          "ec2:Describe*"
          # "ec2:AuthorizeSecurityGroupIngress"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "maat_ecs_service_role_policy_attachment" {
  role       = aws_iam_role.maat_ecs_service_role.name
  policy_arn = aws_iam_policy.maat_ecs_service_role_policy.arn
}

##### ECS Autoscaling Role -----

resource "aws_iam_role" "maat_ecs_autoscaling_role" {
  name = "${local.application_name}-ecs-autoscaling-role"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ecs-autoscaling-role"
    }
  )
  assume_role_policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
             "Principal": {
               "Service": "application-autoscaling.amazonaws.com"
            },
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "maat_ecs_autoscaling_role_policy" {
  name = "${local.application_name}-ecs-autoscaling-role-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "application-autoscaling:*",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:PutMetricAlarm",
          "ecs:DescribeServices",
          "ecs:UpdateService"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "maat_ecs_autoscaling_role_policy_attachment" {
  role       = aws_iam_role.maat_ecs_autoscaling_role.name
  policy_arn = aws_iam_policy.maat_ecs_autoscaling_role_policy.arn
}

resource "aws_iam_policy" "maat_ecs_policy_access_params" {
  name = "${local.application_name}-ecs-policy-access-params"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "ssm:GetParameters"
        Resource = [
          "arn:aws:ssm:${local.env_account_region}:${local.env_account_id}:parameter/maat/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "cloudwatch:PutMetricData",
          # "sqs:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "arn:aws:ecr:${local.env_account_region}:374269020027:repository/${local.application_name}-ecr-repo"
      }
    ]
  })

  tags = {
    Name = "${local.application_name}-ecs-policy-access-params"
  }
}

resource "aws_iam_role_policy_attachment" "maat_ecs_tasks_role_policy_attachment_access_params" {
  role       = aws_iam_role.maat_ec2_instance_role.name
  policy_arn = aws_iam_policy.maat_ecs_policy_access_params.arn
}
#### ECS TASK DEFINITION -------

resource "aws_ecs_task_definition" "maat_ecs_task_definition" {
  family             = "${local.application_name}-ecs-task-definition"
  execution_role_arn = aws_iam_role.maat_ec2_instance_role.arn
  task_role_arn      = aws_iam_role.maat_ec2_instance_role.arn

  container_definitions = templatefile("maat-task-definition.json",
    {
      maat_docker_image_tag  = local.application_data.accounts[local.environment].maat_docker_image_tag
      xray_docker_image_tag  = local.application_data.accounts[local.environment].xray_docker_image_tag
      region                 = local.application_data.accounts[local.environment].region
      sentry_env             = local.environment
      maat_orch_base_url     = local.application_data.accounts[local.environment].maat_orch_base_url
      maat_orch_oauth_url    = local.application_data.accounts[local.environment].maat_orch_oauth_url
      maat_db_url            = local.application_data.accounts[local.environment].maat_db_url
      maat_caa_oauth_url     = local.application_data.accounts[local.environment].maat_caa_oauth_url
      maat_caa_oauth_scope   = local.application_data.accounts[local.environment].maat_caa_oauth_scope
      maat_bc_endpoint_url   = local.application_data.accounts[local.environment].maat_bc_endpoint_url
      maat_mlra_url          = local.application_data.accounts[local.environment].maat_mlra_url
      maat_caa_base_url      = local.application_data.accounts[local.environment].maat_caa_base_url
      ecr_url                = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/maat-ecr-repo"
      maat_ecs_log_group     = local.application_data.accounts[local.environment].maat_ecs_log_group
      maat_aws_stream_prefix = local.application_data.accounts[local.environment].maat_aws_stream_prefix
      env_account_region     = local.env_account_region
      env_account_id         = local.env_account_id
      app_log_level          = local.application_data.accounts[local.environment].app_log_level
      maat_ats_oauth_url     = local.application_data.accounts[local.environment].maat_ats_oauth_url
      maat_ats_endpoint      = local.application_data.accounts[local.environment].maat_ats_endpoint
      maat_ats_base_url      = local.application_data.accounts[local.environment].maat_ats_base_url

    }
  )

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-task-definition"
    }
  )
}

#### ECS Scaling target ------

resource "aws_appautoscaling_target" "maat_ecs_scaling_target" {
  max_capacity       = local.application_data.accounts[local.environment].maat_ecs_scaling_target_max
  min_capacity       = local.application_data.accounts[local.environment].maat_ecs_scaling_target_min
  resource_id        = "service/${aws_ecs_cluster.maat_ecs_cluster.name}/${aws_ecs_service.maat_ecs_service.name}"
  role_arn           = aws_iam_role.maat_ecs_autoscaling_role.arn
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

#### ECS Scaling Policies -------

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

#### ECS CLOUDWATCH LOG GROUP & KEY ------

resource "aws_kms_key" "maat_ecs_cloudwatch_log_key" {
  description         = "KMS key to be used for encrypting the CloudWatch logs in the Log Groups"
  enable_key_rotation = true

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ecs-key"
    }
  )
}

resource "aws_kms_key_policy" "maat_ecs_cloudwatch_log_key_policy" {
  key_id = aws_kms_key.maat_ecs_cloudwatch_log_key.id
  policy = jsonencode({
    Id = "key-default-1"
    Statement = [
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.env_account_id}:root"
        }

        Resource = "*"
        Sid      = "Enable IAM User Permissions"
      },
      {
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Effect = "Allow"
        Principal = {
          Service = "logs.eu-west-2.amazonaws.com"
        }
        Resource = "*"
        Sid      = "Enable log service Permissions"
      }
    ]
    Version = "2012-10-17"
  })
}

resource "aws_cloudwatch_log_group" "maat_ecs_cloudwatch_log_group" {
  name              = local.application_data.accounts[local.environment].maat_ecs_log_group
  retention_in_days = 365
  kms_key_id        = aws_kms_key.maat_ecs_cloudwatch_log_key.arn
}

#### ECS Service ------

resource "aws_ecs_service" "maat_ecs_service" {
  name            = "${local.application_name}-ecs-service"
  cluster         = aws_ecs_cluster.maat_ecs_cluster.id
  desired_count   = local.application_data.accounts[local.environment].maat_ecs_service_desired_count
  task_definition = aws_ecs_task_definition.maat_ecs_task_definition.arn
  # iam_role                          = aws_iam_role.maat_ecs_service_role.arn
  depends_on = [aws_lb_listener.external, aws_lb_listener.maat_internal_lb_https_listener]

  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  load_balancer {
    container_name   = upper(local.application_name)
    container_port   = 8080
    target_group_arn = aws_lb_target_group.external.arn
  }

  load_balancer {
    container_name   = upper(local.application_name)
    container_port   = 8080
    target_group_arn = aws_lb_target_group.maat_internal_lb_target_group.arn
  }

  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ecs-service"
    }
  )
}

##### ECS CloudWatch Alarms -------

resource "aws_cloudwatch_metric_alarm" "maat_ecs_high_cpu_alarm" {
  alarm_name          = "${local.application_name}-ecs-high-cpu-alarm"
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
  alarm_actions       = [aws_appautoscaling_policy.maat_ecs_scaling_up_policy.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.maat_ecs_cluster.name
    ServiceName = aws_ecs_service.maat_ecs_service.name
  }
}

resource "aws_cloudwatch_metric_alarm" "maat_ecs_low_cpu_alarm" {
  alarm_name          = "${local.application_name}-ecs-low-cpu-alarm"
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
  alarm_actions       = [aws_appautoscaling_policy.maat_ecs_scaling_down_policy.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.maat_ecs_cluster.name
    ServiceName = aws_ecs_service.maat_ecs_service.name
  }
}
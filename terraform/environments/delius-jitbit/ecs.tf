data "aws_ecs_task_definition" "task_definition" {
  task_definition = "${var.app_name}-task-definition"
  depends_on      = [aws_ecs_task_definition.windows_ecs_task_definition, aws_ecs_task_definition.linux_ecs_task_definition]
}

data "aws_lb_target_group" "target_group" {
    
  tags = {
    "Name" = "${var.app_name}-tg-${var.environment}"
  }
}

#resource "aws_autoscaling_group" "cluster-scaling-group" {
#  vpc_zone_identifier = sort(data.aws_subnets.shared-private.ids)
#  desired_capacity    = var.ec2_desired_capacity
#  min_size            = var.ec2_min_size
#  max_size            = var.ec2_max_size
#
#  launch_template {
#    id      = aws_launch_template.ec2-launch-template.id
#    version = "$Latest"
#  }
#
#  tag {
#    key                 = "Name"
#    value               = "${var.app_name}-cluster-scaling-group"
#    propagate_at_launch = true
#  }
#
#  dynamic "tag" {
#    for_each = var.tags_common

#    content {
#      key                 = tag.key
#      value               = tag.value
#      propagate_at_launch = true
#    }
#  }
#}

# ECS Fargate Security Group

resource "aws_security_group" "app" {

  name        = "${var.app_name}-security-group"
  description = "Allow traffic from load balancer(s)"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-app-security-group"
    }
  )
}

resource "aws_security_group_rule" "lb_egress" {

  security_group_id        = aws_security_group.app.id
  description              = "Allow external lb to send traffic to application"
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "lb_ingress" {

  security_group_id        = aws_security_group.app.id
  description              = "Allow external lb to send traffic in to application sg"
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
}

resource "aws_lb_target_group" "lb_target_group" {
  name                 = "${var.app_name}-lb-target-group"
  port                 = "3000"
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = "30"
  vpc_id               = data.aws_vpc.shared.id

  health_check {
    enabled             = true
    healthy_threshold   = "5"
    interval            = "30"
    port                = "3000"
    protocol            = "HTTP"
    timeout             = "5"
    unhealthy_threshold = "2"
  }

  tags = merge(
    local.tags,
    {
      Name = "${var.app_name}-lb-target-group"
    },
  )
}

resource "aws_lb_listener" "external" {
  depends_on = [
    aws_acm_certificate_validation.external
  ]

  load_balancer_arn = aws_lb.external.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.external.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}

resource "aws_acm_certificate" "external" {
  domain_name       = "${var.app_name}-sandbox.modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = ["*.${var.app_name}-sandbox.modernisation-platform.service.justice.gov.uk"]
  tags = {
    Environment = "test"
  }

  lifecycle {
    create_before_destroy = true
  }
}

// ECS cluster

resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.app_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-cluster-app-security-group"
    }
  )
}

#resource "aws_ecs_cluster_capacity_providers" "ecs_cluster" {
#  cluster_name = aws_ecs_cluster.ecs_cluster.name
#}

// ****


resource "aws_ecs_task_definition" "windows_ecs_task_definition" {
    network_mode              = [local.app_data.accounts[local.environment].network_mode]
    family                    = "${var.app_name}-task-definition"
    count                     = var.container_instance_type == "windows" ? 1 : 0
    execution_role_arn        = aws_iam_role.ecs_task_execution_role.arn
    task_role_arn             = aws_iam_role.ecs_task_execution_role.arn
    requires_compatibilities  = [local.app_data.accounts[local.environment].ecs_type]

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
  cpu                = var.container_cpu
  memory             = var.container_memory
  count              = var.container_instance_type == "linux" ? 1 : 0
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = [local.app_data.accounts[local.environment].ecs_type]

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
    launch_type     = local.app_data.accounts[local.environment].ecs_type

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
    aws_iam_role_policy_attachment.ecs_task_execution_role, aws_ecs_task_definition.windows_ecs_task_definition, aws_ecs_task_definition.linux_ecs_task_definition
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
  name   = "${var.app_name}-ecs-task-execution-s3-policy"
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
        "kms:DescribeKey"
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

##### ECS autoscaling ##########

resource "aws_appautoscaling_target" "scaling_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.appscaling_min_capacity
  max_capacity       = var.appscaling_max_capacity
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

# Set up CloudWatch group and log stream and retain logs for 30 days
resource "aws_cloudwatch_log_group" "cloudwatch_group" {
  #checkov:skip=CKV_AWS_158:Temporarily skip KMS encryption check while logging solution is being updated
  name              = "${var.app_name}-ecs"
  retention_in_days = 30
  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-ecs-cloudwatch-group"
    }
  )
}

resource "aws_cloudwatch_log_stream" "cloudwatch_stream" {
  name           = "${var.app_name}-log-stream"
  log_group_name = aws_cloudwatch_log_group.cloudwatch_group.name
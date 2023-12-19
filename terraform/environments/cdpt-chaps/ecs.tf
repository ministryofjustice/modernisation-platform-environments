data "aws_ecs_task_definition" "task_definition" {
  task_definition = aws_ecs_task_definition.chaps_task_definition.family
  depends_on      = [aws_ecs_task_definition.chaps_task_definition]
}

resource "aws_iam_policy" "ec2_instance_policy" { #tfsec:ignore:aws-iam-no-policy-wildcards
  name = "${local.application_name}-ec2-instance-policy"

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
                "logs:PutLogEvents",
                "s3:ListBucket",
                "s3:*Object*",
                "kms:Decrypt",
                "kms:Encrypt",
                "kms:GenerateDataKey",
                "kms:ReEncrypt",
                "kms:GenerateDataKey",
                "kms:DescribeKey"
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

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${local.application_name}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "deployment_logs" {
  name              = "/aws/events/deploymentLogs"
  retention_in_days = "7"
}

resource "aws_ecs_task_definition" "chaps_task_definition" {
  family                   = "chapsFamily"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.app_execution.arn
  task_role_arn            = aws_iam_role.app_task.arn
  container_definitions = jsonencode([
    {
      name      = "${local.application_name}-container"
      image     = "${local.ecr_url}:${local.application_data.accounts[local.environment].docker_image_tag}"
      cpu       = 1024
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group = "${local.application_name}-ecs",
          awslogs-region = "eu-west-2",
          awslogs-stream-prefix = local.application_name
        }
      }
      environment = [
      ]
    }
  ])
  runtime_platform {
    operating_system_family = "WINDOWS_SERVER_2019_CORE"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_service" "ecs_service" {
  depends_on = [
    aws_lb_listener.listener
  ]

  name                              = var.networking[0].application
  cluster                           = aws_ecs_cluster.ecs_cluster.id
  task_definition                   = aws_ecs_task_definition.chaps_task_definition.arn
  desired_count                     = local.application_data.accounts[local.environment].app_count
  health_check_grace_period_seconds = 180

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.chaps.name
    weight            = 1
  }

  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.chaps_tg.arn
    container_name   = "${local.application_name}-container"
    container_port   = 80
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}"
    }
  )
}

resource "aws_ecs_capacity_provider" "chaps" {
  name = "${local.application_name}-ecs-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.cluster-scaling-group.arn

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ecs-capacity-provider"
    }
  )
}

resource "aws_ecs_cluster_capacity_providers" "cdpt-chaps" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = [aws_ecs_capacity_provider.chaps.name]
}

resource "aws_autoscaling_group" "cluster-scaling-group" {
  vpc_zone_identifier       = sort(data.aws_subnets.shared-private.ids)
  name                      = "${local.application_name}-cluster-scaling-group"
  desired_capacity          = local.application_data.accounts[local.environment].ec2_desired_capacity
  max_size                  = local.application_data.accounts[local.environment].ec2_max_size
  min_size                  = local.application_data.accounts[local.environment].ec2_min_size
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.ec2-launch-template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.application_name}-cluster-scaling-group"
    propagate_at_launch = true
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

resource "aws_security_group" "cluster_ec2" {
  name        = "${local.application_name}-cluster-ec2-security-group"
  description = "controls access to the cluster ec2 instance"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description     = "allow access on HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.chaps_lb_sc.id]
  }

  ingress {
    description     = "allow access on HTTP"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.chaps_lb_sc.id]
  }

  ingress {
    description = "allow access on HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "Cluster EC2 loadbalancer egress rule"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = []
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-cluster-ec2-security-group"
    }
  )
}

# EC2 launch template - settings to use for new EC2s added to the group
# Note - when updating this you will need to manually terminate the EC2s
# so that the autoscaling group creates new ones using the new launch template

resource "aws_launch_template" "ec2-launch-template" {
  name_prefix            = "${local.application_name}-ec2-launch-template"
  image_id               = local.application_data.accounts[local.environment].ami_image_id
  instance_type          = local.application_data.accounts[local.environment].instance_type
  key_name               = local.application_data.accounts[local.environment].key_name
  ebs_optimized          = true

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
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

  user_data = local.user_data

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

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${local.application_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_iam_role" "ec2_instance_role" {
  name = "${local.application_name}-ec2-instance-role"

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

resource "aws_iam_role" "app_execution" {
  name = "execution-${var.networking[0].application}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(
    local.tags,
    {
      Name = "execution-${var.networking[0].application}"
    },
  )
}

resource "aws_iam_role_policy" "app_execution" {
  name = "execution-${var.networking[0].application}"
  role = aws_iam_role.app_execution.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
           "Action": [
              "ecr:*",
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents",
              "logs:DescribeLogStreams",
              "secretsmanager:GetSecretValue"
           ],
           "Resource": "*",
           "Effect": "Allow"
      }
    ]
  }
  EOF
}

resource "aws_iam_role" "app_task" {
  name = "task-${var.networking[0].application}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(
    local.tags,
    {
      Name = "task-${var.networking[0].application}"
    },
  )
}

resource "aws_iam_role_policy" "app_task" {
  name = "task-${var.networking[0].application}"
  role = aws_iam_role.app_task.id

  policy = <<-EOF
  {
   "Version": "2012-10-17",
   "Statement": [
     {
       "Effect": "Allow",
        "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ecr:*",
          "iam:*",
          "ec2:*"
        ],
       "Resource": "*"
     }
   ]
  }
  EOF
}

resource "aws_security_group" "ecs_service" {
  name_prefix = "ecs-service-sg-"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    description     = "Allow traffic on port 80 from load balancer"
    security_groups = [aws_security_group.chaps_lb_sc.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# AWS EventBridge rule
resource "aws_cloudwatch_event_rule" "ecs_events" {
  name        = "ecs-events"
  description = "Capture all ECS events"

  event_pattern = jsonencode({
    "source" : ["aws.ecs"],
    "detail" : {
      "clusterArn" : [aws_ecs_cluster.ecs_cluster.arn]
    }
  })
}

# AWS EventBridge target
resource "aws_cloudwatch_event_target" "logs" {
  depends_on = [aws_cloudwatch_log_group.deployment_logs]
  rule       = aws_cloudwatch_event_rule.ecs_events.name
  target_id  = "send-to-cloudwatch"
  arn        = aws_cloudwatch_log_group.deployment_logs.arn
}

resource "aws_cloudwatch_log_resource_policy" "ecs_logging_policy" {
  policy_document = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "TrustEventsToStoreLogEvent",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : ["events.amazonaws.com", "delivery.logs.amazonaws.com"]
        },
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/events/*:*"
      }
    ]
  })
  policy_name = "TrustEventsToStoreLogEvents"
}

# Set up CloudWatch group and log stream and retain logs for 30 days
resource "aws_cloudwatch_log_group" "cloudwatch_group" {
  name              = "${local.application_name}-ecs"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "cloudwatch_stream" {
  name           = "${local.application_name}-log-stream"
  log_group_name = aws_cloudwatch_log_group.cloudwatch_group.name
}

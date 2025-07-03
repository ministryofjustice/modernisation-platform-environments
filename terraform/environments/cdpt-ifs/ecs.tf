data "aws_ecs_task_definition" "task_definitions" {
  task_definition = aws_ecs_task_definition.ifs_task_definition.family
}

data "aws_ecs_task_definition" "latest_task_definition" {
  task_definition = "${aws_ecs_task_definition.ifs_task_definition.family}:${data.aws_ecs_task_definition.task_definitions.revision}"
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
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:GetLogEvents",
                "logs:PutLogEvents",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutRetentionPolicy",
                "s3:ListBucket",
                "s3:*Object*",
                "kms:Decrypt",
                "kms:Encrypt",
                "kms:GenerateDataKey",
                "kms:ReEncrypt",
                "kms:GenerateDataKey",
                "kms:DescribeKey",
                "rds:Connect",
                "rds:DescribeDBInstances"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_cloudwatch_log_group" "deployment_logs" {
  name              = "/aws/events/deploymentLogs"
  retention_in_days = "7"
}

resource "aws_iam_role_policy_attachment" "attach_ec2_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ec2_instance_policy.arn
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

resource "aws_ecs_task_definition" "ifs_task_definition" {
  family                   = "ifsFamily"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.app_execution.arn
  task_role_arn            = aws_iam_role.app_task.arn
  container_definitions = jsonencode([
    {
      name      = "${local.application_name}-container"
      image     = "${local.ecr_url}:${local.application_data.accounts[local.environment].environment_name}"
      cpu       = 2048
      memory    = 2048
      essential = true
      portMappings = [
        {
          containerPort = local.application_data.accounts[local.environment].container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "${local.application_name}-ecs",
          awslogs-region        = "eu-west-2",
          awslogs-stream-prefix = local.application_name
        }
      }
      environment = [
        {
          name  = "RDS_HOSTNAME"
          value = "${aws_db_instance.database.address}"
        },
        {
          name  = "RDS_USERNAME"
          value = "${aws_db_instance.database.username}"
        },
        {
          name  = "DB_NAME"
          value = "${local.application_data.accounts[local.environment].db_name}"
        },
        {
          name  = "CLIENT_ID"
          value = "${local.application_data.accounts[local.environment].client_id}"
        },
        {
          name  = "ENV_NAME"
          value = "${local.application_data.accounts[local.environment].env_name}"
        }
      ]
      secrets = [
        {
          name : "RDS_PASSWORD",
          valueFrom : aws_secretsmanager_secret_version.dbase_password.arn
        }
      ],
    }
  ])
}


resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${local.application_name}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
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

# EC2 launch template - settings to use for new EC2s added to the group
# Note - when updating this you will need to manually terminate the EC2s
# so that the autoscaling group creates new ones using the new launch template

resource "aws_launch_template" "ec2-launch-template" {
  name_prefix   = "${local.application_name}-ec2-launch-template"
  image_id      = "resolve:ssm:/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-ECS_Optimized/image_id"
  instance_type = local.application_data.accounts[local.environment].instance_type
  key_name      = "${local.application_name}-ec2"
  ebs_optimized = true

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.cluster_ec2.id, aws_security_group.db.id]
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
      "Name"         = "${local.application_name}-ecs-cluster"
      "ForceRefresh" = timestamp()
    }), local.tags)
  }

  tags = merge(tomap({
    "Name" = "${local.application_name}-ecs-cluster-template"
  }), local.tags)
}

resource "aws_security_group" "cluster_ec2" {
  name        = "${local.application_name}-cluster-ec2-security-group"
  description = "controls access to the cluster ec2 instance"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description     = "allow access on HTTP from load balancer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.ifs_lb_sc.id]
  }

  ingress {
    description     = "Allow RDP ingress"
    from_port       = 3389
    to_port         = 3389
    protocol        = "tcp"
    security_groups = [module.bastion_linux.bastion_security_group]
  }

  egress {
    description = "Cluster EC2 loadbalancer egress rule"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-cluster-ec2-security-group"
    }
  )
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${local.application_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_ecs_service" "ecs_service" {
  name                              = var.networking[0].application
  cluster                           = aws_ecs_cluster.ecs_cluster.id
  task_definition                   = data.aws_ecs_task_definition.latest_task_definition.arn
  desired_count                     = local.application_data.accounts[local.environment].app_count
  health_check_grace_period_seconds = 300
  force_new_deployment              = true
  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ifs.name
    weight            = 1
  }

  depends_on = [
    aws_lb_listener.https_listener,
    aws_ecs_task_definition.ifs_task_definition
  ]

  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  ordered_placement_strategy {
    field = "cpu"
    type  = "binpack"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ifs_target_group.arn
    container_name   = "${local.application_name}-container"
    container_port   = local.application_data.accounts[local.environment].container_port
  }

  network_configuration {
    subnets         = data.aws_subnets.shared-private.ids
    security_groups = [aws_security_group.ecs_service.id]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}"
    }
  )
}

resource "aws_ecs_capacity_provider" "ifs" {
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

resource "aws_ecs_cluster_capacity_providers" "cdpt-ifs" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = [aws_ecs_capacity_provider.ifs.name]
}

resource "aws_autoscaling_group" "cluster-scaling-group" {
  vpc_zone_identifier       = sort(data.aws_subnets.shared-private.ids)
  name                      = "${local.application_name}-cluster-scaling-group"
  desired_capacity          = local.application_data.accounts[local.environment].ec2_desired_capacity
  max_size                  = local.application_data.accounts[local.environment].ec2_max_size
  min_size                  = local.application_data.accounts[local.environment].ec2_min_size
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.ec2-launch-template.id
    version = aws_launch_template.ec2-launch-template.latest_version
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

resource "aws_key_pair" "ec2-user" {
  key_name   = "${local.application_name}-ec2"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwVil3c3Nh/F6S1IzMFUMhykwj1SwQEXVvNghpUW5Ncm82ibJqtVccgCFW96HoHO7Bv8jt5O+TrfENlNI6yywASKEiJRDNUpBBK/UCqXQrYJ0KTvJ7FHegQjrxBOM/Lo3o3IniB2lNTe8hijBMrdaeKivWjB2YKTJxLFdUdLFjBop5uH0gL5Or6+P5/CyKmkIftn3Wazyq4Oe3mYQhB9Gr45/T8/UZCPnWWZ/p7AB3hH5jVO3BqHsB0t3YqJrbCV3Uo85xM62BBBV0AcWXNADY2f4A+6zcUX6j6BIfgAmYP3EQCZBxFq0BgxurF7xIh7CIjl4iIMQJ0sz3uoyLdh9f alistair.curtis@MJ004521"
  tags       = local.tags
}

resource "aws_security_group" "ecs_service" {
  name_prefix = "ecs-service-sg-"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    description     = "Allow traffic on port 80 from load balancer"
    security_groups = [module.lb_access_logs_enabled.security_group.id]
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

resource "aws_iam_role_policy_attachment" "bastion_managed" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2_instance_role.name
}

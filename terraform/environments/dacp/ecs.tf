resource "aws_ecs_cluster" "dacp_cluster" {
  name = "dacp_cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "deployment_logs" {
  name = "/aws/events/deploymentLogs"
  retention_in_days = "7"
}

resource "aws_ecs_task_definition" "dacp_task_definition" {
  family                   = "dacpFamily"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.app_execution.arn
  task_role_arn            = aws_iam_role.app_task.arn
  cpu                      = 2048
  memory                   = 4096
  container_definitions = jsonencode([
    {
      name      = "dacp-container"
      image     = "${aws_ecr_repository.dacp_ecr_repo.repository_url}:latest"
      cpu       = 2048
      memory    = 4096
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
          hostPort      = 80
        }
      ]
      environment = [
        {
          name  = "RDS_HOSTNAME"
          value = "${aws_db_instance.dacp_db.address}"
        },
        {
          name  = "RDS_PORT"
          value = "${local.application_data.accounts[local.environment].rds_port}"
        },
        {
          name  = "RDS_USERNAME"
          value = "${aws_db_instance.dacp_db.username}"
        },
        {
          name  = "RDS_PASSWORD"
          value = "${aws_db_instance.dacp_db.password}"
        },
        {
          name  = "DB_NAME"
          value = "${aws_db_instance.dacp_db.db_name}"
        },
        {
          name  = "supportEmail"
          value = "${local.application_data.accounts[local.environment].support_email}"
        },
        {
          name  = "supportTeam"
          value = "${local.application_data.accounts[local.environment].support_team}"
        },
        {
          name  = "ida:ClientId"
          value = "${local.application_data.accounts[local.environment].client_id}"
        }
      ]
    }
  ])
  runtime_platform {
    operating_system_family = "WINDOWS_SERVER_2019_CORE"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_service" "dacp_ecs_service" {
  depends_on = [
    aws_lb_listener.dacp_lb
  ]

  name                              = var.networking[0].application
  cluster                           = aws_ecs_cluster.dacp_cluster.id
  task_definition                   = aws_ecs_task_definition.dacp_task_definition.arn
  launch_type                       = "FARGATE"
  enable_execute_command            = true
  desired_count                     = 2
  health_check_grace_period_seconds = 180

  network_configuration {
    subnets          = data.aws_subnets.shared-public.ids
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.dacp_target_group.arn
    container_name   = "dacp-container"
    container_port   = 80
  }

  deployment_controller {
    type = "ECS"
  }
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
              "logs:*",
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
          "logs:*",
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
    security_groups = [aws_security_group.dacp_lb_sc.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecr_repository" "dacp_ecr_repo" {
  name         = "dacp-ecr-repo"
  force_delete = true
}

# AWS EventBridge rule
resource "aws_cloudwatch_event_rule" "ecs_events" {
  name        = "ecs-events"
  description = "Capture all ECS events"

  event_pattern = jsonencode({
    "source" : ["aws.ecs"],
    "detail" : {
      "clusterArn" : [aws_ecs_cluster.dacp_cluster.arn]
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
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "TrustEventsToStoreLogEvent",
        "Effect": "Allow",
        "Principal": {
          "Service": ["events.amazonaws.com", "delivery.logs.amazonaws.com"]
        },
        "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/events/*:*"
      }
    ]
  })
  policy_name     = "TrustEventsToStoreLogEvents"
}
resource "aws_ecs_cluster" "tipstaff_cluster" {
  name = "tipstaff_cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "tipstaff_task_definition" {
  family                = "tipstaff-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn    = aws_iam_role.app_execution.arn
  task_role_arn         = aws_iam_role.app_task.arn
  cpu       = 1024
  memory    = 2048
  container_definitions = jsonencode([
    {
      name      = "tipstaff-container"
      image     = "mcr.microsoft.com/windows/servercore/iis"
      cpu       = 1024
      memory    = 2048
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
          name  = "DB_HOST"
          value = "${aws_db_instance.tipstaffdbdev.address}"
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_USER"
          value = "${jsondecode(data.aws_secretsmanager_secret_version.db_username.secret_string)["LOCAL_DB_USERNAME"]}"
        },
        {
          name  = "DB_PASSWORD"
          value = "${jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["LOCAL_DB_PASSWORD"]}"
        }
      ]
    }
  ])
  runtime_platform {
    operating_system_family = "WINDOWS_SERVER_2019_CORE"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_service" "tipstaff_ecs_service" {
  depends_on = [
    aws_lb_target_group.tipstaff_dev_target_group,
    aws_lb_listener.tipstaff_dev_lb_1,
    aws_lb_listener.tipstaff_dev_lb_2
  ]

  name = var.networking[0].application
  deployment_controller {
    type = "CODE_DEPLOY"
  }
  cluster                           = aws_ecs_cluster.tipstaff_cluster.id
  task_definition                   = aws_ecs_task_definition.tipstaff_task_definition.arn
  launch_type                       = "FARGATE"
  enable_execute_command            = true
  desired_count                     = 1
  health_check_grace_period_seconds = 120

  network_configuration {
    subnets          = data.aws_subnets.shared-public.ids
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tipstaff_dev_target_group.arn
    container_name   = "tipstaff-container"
    container_port   = 80
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
               "logs:CreateLogStream",
               "logs:PutLogEvents",
               "ecr:GetAuthorizationToken"
           ],
           "Resource": "*",
           "Effect": "Allow"
      },
      {
            "Action": [
              "ecr:GetAuthorizationToken",
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:GetRepositoryPolicy",
              "ecr:DescribeRepositories",
              "ecr:ListImages",
              "ecr:DescribeImages",
              "ecr:BatchGetImage",
              "ecr:GetLifecyclePolicy",
              "ecr:GetLifecyclePolicyPreview",
              "ecr:ListTagsForResource",
              "ecr:DescribeImageScanFindings"
            ],
              "Resource": "*",
            "Effect": "Allow"
      },
      {
          "Action": [
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
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
          "ecr:DescribeImageScanFindings",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
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
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Create ECR Repository
resource "aws_ecr_repository" "tipstaff-ecr-repo" {
  name = "tipstaff-ecr-repo"
}
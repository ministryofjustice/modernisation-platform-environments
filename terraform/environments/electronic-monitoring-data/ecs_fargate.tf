# --------------------------------------------------
# ears sars cluster - just one for now
# --------------------------------------------------

resource "aws_ecs_cluster" "ears_sars_app" {
  name = "ear-sars-ecs-cluster"
  tags =  merge(
    local.tags
  )
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }
}

# --------------------------------------------------
# exceution role
# --------------------------------------------------

data "aws_iam_policy_document" "ecs_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_execution_policy" {
  statement{
    effect  = "Allow"
    actions = [
        "ecs:*",
        "elasticloadbalancing:*",
        "cloudwatch:*",
        "logs:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "ears-sars-app-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_policy.json
}
resource "aws_iam_policy" "ecs_execution_policy" {
  name = "ears-sars-app-ecs-execution-role-policy"
  policy = data.aws_iam_policy_document.ecs_execution_policy.json
}
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_execution_policy.arn
}

# ---------------------------------------------------
# task role
# ---------------------------------------------------

data "aws_iam_policy_document" "ecs_task_policy" {
  statement{
    effect  = "Allow"
    actions = [
        "s3:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "ears-sars-app-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_policy.json
}
resource "aws_iam_policy" "ecs_task_policy" {
  name = "ears-sars-app-ecs-task-role-policy"
  policy = data.aws_iam_policy_document.ecs_task_policy.json
}
resource "aws_iam_role_policy_attachment" "ecs_task_role_policy_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

resource "aws_cloudwatch_log_group" "ecs" {
  name = "/aws/ecs/ears-sars-app/cluster"
}

resource "aws_ecs_task_definition" "ears_sars_api" {
  family                   = "ears-sars-app-api-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  cpu                      = 2048
  memory                   = 2048
  container_definitions = jsonencode([
    {
      name    = "ears-sars-app-api-container"
      image   = "${var.image}"
      command = ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
      portMappings = [
        {
          containerPort = local.application_data.accounts[local.environment].container_port
          protocol      = "tcp"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-stream-prefix = "ears-sars-app"
          awslogs-region        = "eu-west-2"
        }
      }
    }
  ])
}

# ---------------------------------------------------
# security group
# ---------------------------------------------------

resource "aws_security_group" "ecs_service" {
  name_prefix = "ears_sars_sg"
  vpc_id      = data.aws_vpc.shared.id

  # needs egress to connect to sharepoint
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# ---------------------------------------------------
# Deployment
# ---------------------------------------------------

resource "aws_ecs_service" "ears_sars_api" {
  name            = "ears-sars-app-ecs-service"
  cluster         = aws_ecs_cluster.ears_sars_app.name
  launch_type     = "FARGATE"
  desired_count   = 1
  task_definition = aws_ecs_task_definition.api.arn

  network_configuration {
    subnets         = data.aws_subnets.shared-private.ids
    security_groups = [aws_security_group.ecs_service.id]
  }
  

  lifecycle {
    ignore_changes = [desired_count]
  }
}

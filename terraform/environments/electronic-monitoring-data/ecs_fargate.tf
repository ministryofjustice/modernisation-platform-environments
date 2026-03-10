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
  statement {
    effect = "Allow"
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
  name   = "ears-sars-app-ecs-execution-role-policy"
  policy = data.aws_iam_policy_document.ecs_execution_policy.json
}
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_execution_policy.arn
}

resource "aws_iam_role" "ecs_gdpr_execution_role" {
  name               = "emds-gdpr-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_policy.json
}
resource "aws_iam_policy" "ecs_gdpr_execution_policy" {
  name   = "emds-gdpr-ecs-execution-role-policy"
  policy = data.aws_iam_policy_document.ecs_execution_policy.json
}
resource "aws_iam_role_policy_attachment" "ecs_gdpr_execution_role_policy_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_gdpr_execution_policy.arn
}

resource "aws_ecs_cluster" "emds-gdpr-cluster" {
  name = "emds-gdpr-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.example.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_ecs_task_definition" "my_app_task" {
  family                   = "my_app_task" 
  container_definitions    = <<DEFINITION
  [
    {
      "name": "my_app_task",
      "image": "711744175370.dkr.ecr.ap-south-1.amazonaws.com/my-app:fc29c37-2023-06-26-09-11",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 8080
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] 
  network_mode             = "awsvpc"
  memory                   = 512         
  cpu                      = 256         
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"
}



resource "aws_ecs_task_definition" "test" {
  family                   = "test"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  container_definitions    = <<TASK_DEFINITION
[
  {
    "name": "iis",
    "image": "mcr.microsoft.com/windows/servercore/iis",
    "cpu": 1024,
    "memory": 2048,
    "essential": true
  }
]
TASK_DEFINITION

  runtime_platform {
    operating_system_family = "WINDOWS_SERVER_2019_CORE"
    cpu_architecture        = "X86_64"
  }
}
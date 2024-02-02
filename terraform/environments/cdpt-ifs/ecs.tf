data "aws_ecs_task_definition" "task_definition" {
  task_definition = aws_ecs_task_definition.ifs_task_definition.family
  depends_on      = [aws_ecs_task_definition.ifs_task_definition]
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
      cpu       = 1024
      memory    = 1024
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
#        {
#          name  = "RDS_HOSTNAME"
#          value = "${aws_db_instance.database.address}"
#        },
#        {
#          name  = "RDS_USERNAME"
#          value = "${aws_db_instance.database.username}"
#        },
#        {
#          name  = "DB_NAME"
#          value = "${local.application_data.accounts[local.environment].db_name}"
#        },
        {
         name  = "CLIENT_ID"
          value = "${local.application_data.accounts[local.environment].client_id}"
        }
      ]
#      secrets = [
#        {
#          name : "RDS_PASSWORD",
#          valueFrom : aws_secretsmanager_secret_version.db_password.arn
#        }
#      ]
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


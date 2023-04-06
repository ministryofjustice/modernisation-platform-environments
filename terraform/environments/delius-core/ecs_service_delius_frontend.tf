##
# Create service and task definitions for delius-testing-frontend
##


##
# SSM Parameter Store for delius-core-frontend
##

resource "aws_ssm_parameter" "delius_core_frontend_env_var_jdbc_url" {
  name  = format("/%s/JCBC_URL", local.application_name)
  type  = "SecureString"
  value = format("jdbc:oracle:thin:@//%s:%s/%s", aws_db_instance.delius-core.address, aws_db_instance.delius-core.port, local.db_name)
  tags  = local.tags
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "delius_core_frontend_env_var_jdbc_password" {
  name  = format("/%s/JCBC_PASSWORD", local.application_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  tags  = local.tags
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "delius_core_frontend_env_var_test_mode" {
  name  = format("/%s/TEST_MODE", local.application_name)
  type  = "String"
  value = "true"
  tags  = local.tags
}

resource "aws_ssm_parameter" "delius_core_frontend_env_var_dev_username" {
  name  = format("/%s/DEV_USERNAME", local.application_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags
}

resource "aws_ssm_parameter" "delius_core_frontend_env_var_dev_password" {
  name  = format("/%s/DEV_PASSWORD", local.application_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags
}

##
# IAM for ECS services and tasks
##
data "aws_iam_policy_document" "delius_core_frontend_ecs_task" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "delius_core_frontend_ecs_task" {
  name               = format("%s-task", local.frontend_fully_qualified_name)
  assume_role_policy = data.aws_iam_policy_document.delius_core_frontend_ecs_task.json
  tags               = local.tags
}

data "aws_iam_policy_document" "delius_core_frontend_ecs_service" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "delius_core_frontend_ecs_service" {
  name               = format("%s-service", local.frontend_fully_qualified_name)
  assume_role_policy = data.aws_iam_policy_document.delius_core_frontend_ecs_service.json
  tags               = local.tags
}

data "aws_iam_policy_document" "delius_core_frontend_ecs_service_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloafrontendalancing:Describe*",
      "elasticloafrontendalancing:DeregisterInstancesFromLoafrontendalancer",
      "elasticloafrontendalancing:RegisterInstancesWithLoafrontendalancer",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress",
      "elasticloafrontendalancing:RegisterTargets",
      "elasticloafrontendalancing:DeregisterTargets"
    ]
  }
}

resource "aws_iam_role_policy" "delius_core_frontend_ecs_service" {
  name   = format("%s-service", local.frontend_fully_qualified_name)
  policy = data.aws_iam_policy_document.delius_core_frontend_ecs_service_policy.json
  role   = aws_iam_role.delius_core_frontend_ecs_service.id
}

data "aws_iam_policy_document" "delius_core_frontend_ecs_ssm_exec" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
  }
}

resource "aws_iam_role_policy" "delius_core_frontend_ecs_ssm_exec" {
  name   = format("%s-service-ssm-exec", local.frontend_fully_qualified_name)
  policy = data.aws_iam_policy_document.delius_core_frontend_ecs_ssm_exec.json
  role   = aws_iam_role.delius_core_frontend_ecs_task.id
}

# IAM role that the Amazon ECS container agent and the Docker daemon can assume
data "aws_iam_policy_document" "delius_core_frontend_ecs_task_exec" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "delius_core_frontend_ecs_exec" {
  name               = format("%s-task-exec", local.frontend_fully_qualified_name)
  assume_role_policy = data.aws_iam_policy_document.delius_core_frontend_ecs_task_exec.json
  tags               = local.tags
}

data "aws_iam_policy_document" "delius_core_frontend_ecs_exec" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ssm:GetParameters",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
  }
}

resource "aws_iam_role_policy" "delius_core_frontend_ecs_exec" {
  name   = format("%s-task-exec", local.frontend_fully_qualified_name)
  policy = data.aws_iam_policy_document.delius_core_frontend_ecs_exec.json
  role   = aws_iam_role.delius_core_frontend_ecs_exec.id
}


##
# Task definition and container
##
resource "aws_ecs_task_definition" "delius_core_frontend_task_definition" {
  container_definitions = jsonencode(
    [
      {
        cpu       = 1024
        essential = true
        image     = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-weblogic-ecr-repo:${local.frontend_image_tag}"
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = local.frontend_fully_qualified_name
            awslogs-region        = data.aws_region.current.name
            awslogs-stream-prefix = local.frontend_fully_qualified_name
          }
        }
        memory      = 4096
        mountPoints = []
        name        = "${local.frontend_fully_qualified_name}"
        portMappings = [
          {
            containerPort = local.frontend_container_port
            hostPort      = local.frontend_container_port
            protocol      = "tcp"
          },
        ]
        readonlyRootFilesystem = false
        volumesFrom            = []
        secrets = [
          {
            name      = "JDBC_URL"
            valueFrom = aws_ssm_parameter.delius_core_frontend_env_var_jdbc_url.arn
          },
          {
            name      = "JDBC_PASSWORD"
            valueFrom = aws_ssm_parameter.delius_core_frontend_env_var_jdbc_password.arn
          },
          {
            name      = "DEV_USERNAME"
            valueFrom = aws_ssm_parameter.delius_core_frontend_env_var_dev_username.arn
          },
          {
            name      = "DEV_PASSWORD"
            valueFrom = aws_ssm_parameter.delius_core_frontend_env_var_dev_password.arn
          },
          {
            name      = "TEST_MODE"
            valueFrom = aws_ssm_parameter.delius_core_frontend_env_var_test_mode.arn
          }
        ]
      }
  ])
  cpu                = "1024"
  execution_role_arn = aws_iam_role.delius_core_frontend_ecs_exec.arn
  family             = local.frontend_fully_qualified_name

  memory       = "4096"
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE",
  ]

  skip_destroy  = false
  tags          = local.tags
  task_role_arn = aws_iam_role.delius_core_frontend_ecs_task.arn
}

# ##
# # Service and task deployment
# ##
# Pre-req - security groups
resource "aws_security_group" "delius_core_frontend_security_group" {
  name        = "Delius Core Frontend Weblogic"
  description = "Rules for the delius testing frontend ecs service"
  vpc_id      = data.aws_vpc.shared.id
  tags        = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "delius_core_frontend_security_group_ingress_private_subnets" {
  security_group_id            = aws_security_group.delius_core_frontend_security_group.id
  description                  = "load balancer to weblogic frontend"
  from_port                    = local.frontend_container_port
  to_port                      = local.frontend_container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
}

resource "aws_vpc_security_group_egress_rule" "delius_core_frontend_security_group_egress_internet" {
  security_group_id = aws_security_group.delius_core_frontend_security_group.id
  description       = "outbound from weblogic to any secure endpoint"
  ip_protocol       = "tcp"
  to_port           = 443
  from_port         = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "delius_core_frontend_security_group_egress_db" {
  security_group_id            = aws_security_group.delius_core_frontend_security_group.id
  description                  = "outbound from the testing frontend ecs service"
  ip_protocol                  = "tcp"
  to_port                      = local.db_port
  from_port                    = local.db_port
  referenced_security_group_id = aws_security_group.delius_db_security_group.id
}

# Pre-req - CloudWatch log group
# By default, server-side-encryption is used
resource "aws_cloudwatch_log_group" "delius_core_frontend_log_group" {
  name              = local.frontend_fully_qualified_name
  retention_in_days = 7
  tags              = local.tags
}

# Create the ECS service
resource "aws_ecs_service" "delius-frontend-service" {
  cluster         = aws_ecs_cluster.aws_ecs_cluster.id
  name            = local.frontend_fully_qualified_name
  task_definition = aws_ecs_task_definition.delius_core_frontend_task_definition.arn
  network_configuration {
    assign_public_ip = false
    subnets          = data.aws_subnets.private-public.ids
    security_groups  = [aws_security_group.delius_core_frontend_security_group.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.delius_core_frontend_target_group.arn
    container_name   = local.frontend_fully_qualified_name
    container_port   = local.frontend_container_port
  }

  desired_count                      = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  enable_execute_command             = true
  force_new_deployment               = true
  launch_type                        = "FARGATE"
  platform_version                   = "LATEST"
  propagate_tags                     = "SERVICE"
  tags                               = local.tags
  triggers                           = {} # Change this for force redeployment

}

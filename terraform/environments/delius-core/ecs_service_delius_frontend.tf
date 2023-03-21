##
# Create service and task definitions for delius-testing-frontend
##


##
# SSM Parameter Store for delius-core-frontend
##

data "aws_ssm_parameter" "delius_core_frontend_envs" {
  name = "${local.application_name}-${local.frontend_service_name}-envs"
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

        environment = [for key, value in jsondecode(data.aws_ssm_parameter.delius_core_frontend_envs.value) : { name = key, value = value }]
      }
  ])
  cpu = "1024"
  # ephemeral_storage {
  #   size_in_gib = 40
  # }
  execution_role_arn = aws_iam_role.delius_core_frontend_ecs_exec.arn
  family             = local.frontend_fully_qualified_name

  memory       = "4096"
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE",
  ]

  skip_destroy  = false
  tags          = local.tags
  task_role_arn = aws_iam_role.delius_core_frontend_ecs_exec.arn
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
  security_group_id = aws_security_group.delius_core_frontend_security_group.id
  description       = "weblogic to testing frontend"
  for_each = toset(
    [
      data.aws_subnet.private_subnets_a.cidr_block,
      data.aws_subnet.private_subnets_b.cidr_block,
      data.aws_subnet.private_subnets_c.cidr_block
    ]
  )
  from_port   = local.frontend_container_port
  to_port     = local.frontend_container_port
  ip_protocol = "tcp"
  cidr_ipv4   = each.key
}

resource "aws_vpc_security_group_egress_rule" "delius_core_frontend_security_group_egress_internet" {
  security_group_id = aws_security_group.delius_core_frontend_security_group.id
  description       = "outbound from the testing db ecs service"
  ip_protocol       = "tcp"
  to_port           = 443
  from_port         = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# Come back to this to investigate only allowing egress to the DB security group
resource "aws_vpc_security_group_egress_rule" "delius_core_frontend_security_group_egress_db" {
  security_group_id            = aws_security_group.delius_core_frontend_security_group.id
  description                  = "outbound from the testing frontend ecs service"
  ip_protocol                  = "tcp"
  to_port                      = local.db_container_port
  from_port                    = local.db_container_port
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

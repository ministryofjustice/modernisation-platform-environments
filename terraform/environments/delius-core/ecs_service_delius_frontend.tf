##
# Create service and task definitions for delius-testing-frontend
##
locals {
  frontend_service_name         = "testing-frontend"
  frontend_fully_qualified_name = "${local.application_name}-${local.frontend_service_name}"
  frontend_image_tag            = "5.7.4"
  frontend_container_port       = 7001
}

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
        name        = "delius-core-testing-frontend"
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
  name        = "delius weblogic to delius frontend"
  description = "Rules for the delius testing frontend ecs service"
  vpc_id      = data.aws_vpc.shared.id
  tags        = local.tags
}

# Need to rework this
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
  description       = "outbound from the testing frontend ecs service"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
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

# module "deploy" {
#   source                    = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service?ref=f1ace6467418d0df61fd8ff6beabd1c028798d39"
#   container_definition_json = module.container.json_map_encoded_list
#   ecs_cluster_arn           = aws_ecs_cluster.ecs_cluster.arn
#   name                      = local.frontend_fully_qualified_name
#   vpc_id                    = data.aws_vpc.shared.id

#   launch_type  = "FARGATE"
#   network_mode = "awsvpc"

#   task_cpu    = "1024"
#   task_memory = "4096"

#   desired_count = 1

#   service_role_arn   = aws_iam_role.delius_core_frontend_ecs_service.arn
#   task_role_arn      = aws_iam_role.delius_core_frontend_ecs_task.arn
#   task_exec_role_arn = aws_iam_role.delius_core_frontend_ecs_exec.arn

#   environment = local.environment
#   # ecs_load_balancers = [
#   #   {
#   #     target_group_arn = data.aws_lb_target_group.service.arn
#   #     container_name   = local.frontend_service_name
#   #     frontend_container_port   = local.frontend_container_port
#   #   }
#   # ]

#   # security_group_ids = [var.service_security_group_id]

#   subnet_ids = data.aws_subnets.shared-data.ids

#   ignore_changes_task_definition = false

# }

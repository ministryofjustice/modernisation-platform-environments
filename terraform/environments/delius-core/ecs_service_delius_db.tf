##
# Create service and task definitions for delius-testing-db
##

##
# IAM for ECS services and tasks
##
data "aws_iam_policy_document" "delius_db_ecs_task" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "delius_db_ecs_task" {
  name               = format("%s-task", local.db_fully_qualified_name)
  assume_role_policy = data.aws_iam_policy_document.delius_db_ecs_task.json
  tags               = local.tags
}

data "aws_iam_policy_document" "delius_db_ecs_service" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "delius_db_ecs_service" {
  name               = format("%s-service", local.db_fully_qualified_name)
  assume_role_policy = data.aws_iam_policy_document.delius_db_ecs_service.json
  tags               = local.tags
}

data "aws_iam_policy_document" "delius_db_ecs_service_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets"
    ]
  }
}

resource "aws_iam_role_policy" "delius_db_ecs_service" {
  name   = format("%s-service", local.db_fully_qualified_name)
  policy = data.aws_iam_policy_document.delius_db_ecs_service_policy.json
  role   = aws_iam_role.delius_db_ecs_service.id
}

data "aws_iam_policy_document" "delius_db_ecs_ssm_exec" {
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

resource "aws_iam_role_policy" "delius_db_ecs_ssm_exec" {
  name   = format("%s-service-ssm-exec", local.db_fully_qualified_name)
  policy = data.aws_iam_policy_document.delius_db_ecs_ssm_exec.json
  role   = aws_iam_role.delius_db_ecs_task.id
}

# IAM role that the Amazon ECS container agent and the Docker daemon can assume
data "aws_iam_policy_document" "delius_db_ecs_task_exec" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "delius_db_ecs_exec" {
  name               = format("%s-task-exec", local.db_fully_qualified_name)
  assume_role_policy = data.aws_iam_policy_document.delius_db_ecs_task_exec.json
  tags               = local.tags
}

data "aws_iam_policy_document" "delius_db_ecs_exec" {
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

resource "aws_iam_role_policy" "delius_db_ecs_exec" {
  name   = format("%s-task-exec", local.db_fully_qualified_name)
  policy = data.aws_iam_policy_document.delius_db_ecs_exec.json
  role   = aws_iam_role.delius_db_ecs_exec.id
}


##
# Task definition and container
##
resource "aws_ecs_task_definition" "delius_db_task_definition" {
  container_definitions = jsonencode(
    [
      {
        cpu       = 1024
        essential = true
        image     = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-testing-db-ecr-repo:${local.db_image_tag}"
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = local.db_fully_qualified_name
            awslogs-region        = data.aws_region.current.name
            awslogs-stream-prefix = local.db_fully_qualified_name
          }
        }
        memory      = 4096
        mountPoints = []
        name        = "delius-core-testing-db"
        portMappings = [
          {
            containerPort = local.db_port
            hostPort      = local.db_port
            protocol      = "tcp"
          },
        ]
        readonlyRootFilesystem = false
        volumesFrom            = []
      }
  ])
  cpu = "1024"
  ephemeral_storage {
    size_in_gib = 40
  }
  execution_role_arn = aws_iam_role.delius_db_ecs_exec.arn
  family             = local.db_fully_qualified_name

  memory       = "4096"
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE",
  ]

  skip_destroy  = false
  tags          = local.tags
  task_role_arn = aws_iam_role.delius_db_ecs_exec.arn
}

# ##
# # Service and task deployment
# ##
# Pre-req - security groups
resource "aws_security_group" "delius_db_security_group" {
  name        = "Delius Core DB"
  description = "Rules for the delius testing db ecs service"
  vpc_id      = data.aws_vpc.shared.id
  tags        = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "delius_db_security_group_ingress_private_subnets" {
  security_group_id            = aws_security_group.delius_db_security_group.id
  description                  = "weblogic to testing db"
  from_port                    = local.db_port
  to_port                      = local.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.delius_core_frontend_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "delius_db_security_group_ingress_bastion" {
  security_group_id            = aws_security_group.delius_db_security_group.id
  description                  = "bastion to testing db"
  from_port                    = local.db_port
  to_port                      = local.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = module.bastion_linux.bastion_security_group
}

resource "aws_vpc_security_group_egress_rule" "delius_db_security_group_egress_internet" {
  security_group_id = aws_security_group.delius_db_security_group.id
  description       = "outbound from the testing db ecs service"
  ip_protocol       = "tcp"
  to_port           = 443
  from_port         = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# Pre-req - CloudWatch log group
# By default, server-side-encryption is used
resource "aws_cloudwatch_log_group" "delius_db_log_group" {
  name              = local.db_fully_qualified_name
  retention_in_days = 7
  tags              = local.tags
}

# Pre-req - service discovery
# Removed until we're clear on the implementation of service discovery on mod platform

# resource "aws_service_discovery_service" "delius_db_service" {
#   name = local.db_service_name
#   tags = local.tags

#   dns_config {
#     namespace_id   = aws_service_discovery_private_dns_namespace.ecs_cluster_namespace.id
#     routing_policy = "MULTIVALUE"
#     dns_records {
#       ttl  = 30
#       type = "A"
#     }
#   }
# }

# Create the ECS service
resource "aws_ecs_service" "delius-db-service" {
  cluster         = aws_ecs_cluster.aws_ecs_cluster.id
  name            = local.db_fully_qualified_name
  task_definition = aws_ecs_task_definition.delius_db_task_definition.arn
  network_configuration {
    assign_public_ip = false
    subnets          = data.aws_subnets.shared-private.ids
    security_groups  = [aws_security_group.delius_db_security_group.id]
  }
  # Removed until we're clear on the implementation of service discovery on mod platform
  # service_registries {
  #   registry_arn = aws_service_discovery_service.delius_db_service.arn
  # }
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

# Create route 53 record representing above DB endpoint
# This is a _tactical_ and _temporary_ record designed to
# - simulate service discovery, albeit a lesser version of
# - give us a way to see the ECS front end connecting to the ECS backend
# - which gives us an accessible and testable front end app
# At the time of writing, this will be replaced in time with a record pointing to an EC2 Oracle instance
# It assumes that the ECS task for the DB will be long lived (and hence the IP will not get recycled)
resource "aws_route53_record" "delius-core-db" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.inner.zone_id
  name     = "${local.db_service_name}-${local.application_name}.${data.aws_route53_zone.inner.name}"
  type     = "A"
  ttl      = 300
  records  = ["10.26.26.165"]
}

##
# Commenting out remaining sections - we will return to these with a new module
##
# ##
# # Service and task deployment
# ##
# module "container" {
#   source                   = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=tags/0.58.2"
#   container_name           = local.fully_qualified_name
#   container_image          = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.fully_qualified_name}-ecr-repo:${local.image_tag}"
#   container_memory         = "4096"
#   container_cpu            = "1024"
#   essential                = true
#   readonly_root_filesystem = false
#   environment              = []
#   port_mappings = [{
#     containerPort = local.container_port
#     hostPort      = local.container_port
#     protocol      = "tcp"
#   }]
#   log_configuration = {
#     logDriver = "awslogs"
#     options = {
#       "awslogs-group"         = "${local.fully_qualified_name}-ecs"
#       "awslogs-region"        = data.aws_region.current.name
#       "awslogs-stream-prefix" = local.fully_qualified_name
#     }
#   }
#   secrets = [
#   ]
# }

# module "deploy" {
#   source                    = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service?ref=f1ace6467418d0df61fd8ff6beabd1c028798d39"
#   container_definition_json = module.container.json_map_encoded_list
#   ecs_cluster_arn           = aws_ecs_cluster.ecs_cluster.arn
#   name                      = local.db_fully_qualified_name
#   vpc_id                    = data.aws_vpc.shared.id

#   launch_type  = "FARGATE"
#   network_mode = "awsvpc"

#   task_cpu    = "1024"
#   task_memory = "4096"

#   desired_count = 1

#   service_role_arn   = aws_iam_role.delius_db_ecs_service.arn
#   task_role_arn      = aws_iam_role.delius_db_ecs_task.arn
#   task_exec_role_arn = aws_iam_role.delius_db_ecs_exec.arn

#   environment = local.environment
#   # ecs_load_balancers = [
#   #   {
#   #     target_group_arn = data.aws_lb_target_group.service.arn
#   #     container_name   = local.db_service_name
#   #     db_port   = local.db_port
#   #   }
#   # ]

#   # security_group_ids = [var.service_security_group_id]

#   subnet_ids = data.aws_subnets.shared-data.ids

#   ignore_changes_task_definition = false

# }

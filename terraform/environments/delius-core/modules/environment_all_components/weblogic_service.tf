##
# Task definition and container
##
resource "aws_ecs_task_definition" "delius_core_frontend_task_definition" {
  container_definitions = jsonencode(
    [
      {
        cpu       = 1024
        essential = true
        image     = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-weblogic-ecr-repo:${var.weblogic_config.frontend_image_tag}"
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = var.weblogic_config.frontend_fully_qualified_name
            awslogs-region        = "eu-west-2"
            awslogs-stream-prefix = var.weblogic_config.frontend_fully_qualified_name
          }
        }
        memory      = 4096
        mountPoints = []
        name        = "${var.weblogic_config.frontend_fully_qualified_name}"
        portMappings = [
          {
            containerPort = var.weblogic_config.frontend_container_port
            hostPort      = var.weblogic_config.frontend_container_port
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
            name      = "TEST_MODE"
            valueFrom = aws_ssm_parameter.delius_core_frontend_env_var_test_mode.arn
          },
          {
            name      = "LDAP_PORT"
            valueFrom = data.aws_ssm_parameter.delius_core_frontend_env_var_ldap_port.arn
          },
          {
            name      = "LDAP_PRINCIPAL"
            valueFrom = data.aws_ssm_parameter.delius_core_frontend_env_var_ldap_principal.arn
          },
          { name      = "LDAP_CREDENTIAL"
            valueFrom = data.aws_secretsmanager_secret.ldap_credential.arn
          },
          {
            name      = "USER_CONTEXT"
            valueFrom = data.aws_ssm_parameter.delius_core_frontend_env_var_user_context.arn
          },
          {
            name      = "EIS_USER_CONTEXT"
            valueFrom = data.aws_ssm_parameter.delius_core_frontend_env_var_eis_user_context.arn
          }
        ]
        environment = [
          # {
          #   name  = "LDAP_HOST"
          #   value = aws_lb.ldap.dns_name
          # }
        ]
      }
  ])
  cpu                = "1024"
  execution_role_arn = aws_iam_role.delius_core_frontend_ecs_exec.arn
  family             = var.weblogic_config.frontend_fully_qualified_name

  memory       = "4096"
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE",
  ]

  skip_destroy  = false
  tags          = local.tags
  task_role_arn = aws_iam_role.delius_core_frontend_ecs_task.arn
}


# Create the ECS service
resource "aws_ecs_service" "delius-frontend-service" {
  cluster         = module.ecs.ecs_cluster_arn
  name            = var.weblogic_config.frontend_fully_qualified_name
  task_definition = aws_ecs_task_definition.delius_core_frontend_task_definition.arn
  network_configuration {
    assign_public_ip = false
    subnets          = var.network_config.private_subnet_ids
    security_groups  = [aws_security_group.delius_core_frontend_security_group.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.delius_core_frontend_target_group.arn
    container_name   = var.weblogic_config.frontend_fully_qualified_name
    container_port   = var.weblogic_config.frontend_container_port
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

resource "aws_security_group" "delius_core_frontend_security_group" {
  name        = "Delius Core Frontend Weblogic"
  description = "Rules for the delius testing frontend ecs service"
  vpc_id      = var.network_config.shared_vpc_id
  tags        = local.tags
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
  name               = format("%s-task-exec", var.weblogic_config.frontend_fully_qualified_name)
  assume_role_policy = data.aws_iam_policy_document.delius_core_frontend_ecs_task_exec.json
  tags               = local.tags
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
  name               = format("%s-task", var.weblogic_config.frontend_fully_qualified_name)
  assume_role_policy = data.aws_iam_policy_document.delius_core_frontend_ecs_task.json
  tags               = local.tags
}

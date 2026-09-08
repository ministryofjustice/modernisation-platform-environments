##############################################
### ECS Task Definition & Service — LinOTP 3.x + FreeRADIUS
###
### Deployed in root module to reference AD outputs directly.
### Infrastructure (VPC, ALB, NLB, RDS, etc.) remains in workspace-components.
### Uses existing data.terraform_remote_state.workspace_components from platform_data.tf
##############################################

##############################################
### IAM Task Role for ECS Exec
##############################################

resource "aws_iam_role" "ecs_task_role" {
  count = local.environment == "development" ? 1 : 0

  name_prefix = "${local.application_name}-${local.environment}-ecs-task-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-ecs-task-role" }
  )
}

resource "aws_iam_role_policy" "ecs_exec_policy" {
  count = local.environment == "development" ? 1 : 0

  name = "${local.application_name}-${local.environment}-ecs-exec"
  role = aws_iam_role.ecs_task_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

##############################################
### ECS Task Definition
##############################################

resource "aws_ecs_task_definition" "linotp3" {
  count = local.environment == "development" ? 1 : 0

  family                   = "${local.application_name}-${local.environment}-linotp3"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = data.terraform_remote_state.workspace_components.outputs.ecs_task_execution_role_arn
  task_role_arn            = aws_iam_role.ecs_task_role[0].arn

  container_definitions = jsonencode([
    {
      name      = "linotp"
      image     = "${data.terraform_remote_state.workspace_components.outputs.ecr_linotp3_repository_url}:latest"
      essential = true

      portMappings = [
        { containerPort = 5000, protocol = "tcp" }
      ]

      environment = [
        { name = "LINOTP_DB_HOST", value = data.terraform_remote_state.workspace_components.outputs.linotp3_db_endpoint },
        { name = "LINOTP_DB_USER", value = "linotp" },
        # AD LDAP configuration
        { name = "AD_DNS_IPS", value = join(",", aws_directory_service_directory.workspaces_ad[0].dns_ip_addresses) },
        { name = "AD_BIND_DN", value = "CN=Admin,OU=Users,OU=LAAWORKSPACES,DC=laa-workspaces,DC=local" },
        { name = "LINOTP_RESOLVER_NAME", value = "ad-resolver" },
        { name = "LINOTP_REALM_NAME", value = "laa-workspaces" },
        { name = "LINOTP_URL", value = "http://localhost:5000" },
        { name = "LINOTP_ADMIN_USER", value = "admin" },
        # Auto-configuration enabled (Python script, idempotent)
        { name = "ENABLE_AUTO_CONFIG", value = "true" }
      ]

      secrets = [
        { name = "LINOTP_ENC_KEY_VALUE",   valueFrom = data.terraform_remote_state.workspace_components.outputs.linotp3_enc_key_secret_arn },
        { name = "LINOTP_DB_PASSWORD",     valueFrom = data.terraform_remote_state.workspace_components.outputs.linotp3_db_password_secret_arn },
        { name = "LINOTP_ADMIN_PASSWORD",  valueFrom = data.terraform_remote_state.workspace_components.outputs.linotp_admin_password_arn },
        { name = "AD_BIND_PASSWORD",       valueFrom = data.terraform_remote_state.workspace_components.outputs.linotp_ad_bind_password_secret_arn }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -sf http://localhost:5000/manage/ || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 3
        startPeriod = 120
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = data.terraform_remote_state.workspace_components.outputs.ecs_cloudwatch_log_group_name
          "awslogs-region"        = local.application_data.accounts[local.environment].region
          "awslogs-stream-prefix" = "linotp"
        }
      }
    },
    {
      name      = "freeradius"
      image     = "${data.terraform_remote_state.workspace_components.outputs.ecr_freeradius_repository_url}:latest"
      essential = true

      portMappings = [
        { containerPort = 1812, protocol = "udp" },
        { containerPort = 1813, protocol = "udp" }
      ]

      environment = [
        { name = "VPC_CIDR",   value = data.terraform_remote_state.workspace_components.outputs.vpc_cidr_block },
        { name = "LINOTP_URL", value = "http://localhost/validate/simplecheck" }
      ]

      secrets = [
        { name = "RADIUS_SECRET", valueFrom = data.terraform_remote_state.workspace_components.outputs.radius_shared_secret_arn }
      ]

      dependsOn = [
        { containerName = "linotp", condition = "HEALTHY" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = data.terraform_remote_state.workspace_components.outputs.ecs_cloudwatch_log_group_name
          "awslogs-region"        = local.application_data.accounts[local.environment].region
          "awslogs-stream-prefix" = "freeradius"
        }
      }
    }
  ])

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-linotp3-task" }
  )
}

##############################################
### ECS Service
##############################################

resource "aws_ecs_service" "linotp3" {
  count = local.environment == "development" ? 1 : 0

  name                   = "${local.application_name}-${local.environment}-linotp3"
  cluster                = data.terraform_remote_state.workspace_components.outputs.ecs_cluster_id
  task_definition        = aws_ecs_task_definition.linotp3[0].arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = data.terraform_remote_state.workspace_components.outputs.private_subnet_ids
    security_groups  = [data.terraform_remote_state.workspace_components.outputs.ecs_linotp3_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = data.terraform_remote_state.workspace_components.outputs.linotp_portal_target_group_arn
    container_name   = "linotp"
    container_port   = 5000
  }

  load_balancer {
    target_group_arn = data.terraform_remote_state.workspace_components.outputs.radius_nlb_target_group_arn
    container_name   = "freeradius"
    container_port   = 1812
  }

  depends_on = [
    aws_directory_service_directory.workspaces_ad
  ]

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-linotp3-service" }
  )
}

# ECS Cluster

resource "aws_ecs_cluster" "main_cluster" {
  name = "${local.application_name}-sftp-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "sftp_bc_task_definition" {
  family             = "${local.application_name}-sftp-bc-task"
  execution_role_arn = aws_iam_role.bc_ecs_task_execution_role.arn
  network_mode       = "awsvpc"
  requires_compatibilities = [
    "FARGATE",
  ]

  
  cpu    = local.application_data.accounts[local.environment].container_cpu
  memory = local.application_data.accounts[local.environment].container_memory

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = templatefile(
    "${path.module}/templates/task_definition_api.json.tpl",
    {
      app_name           = local.application_data.accounts[local.environment].app_name
      app_image          = local.application_data.accounts[local.environment].app_image
      api_server_port    = local.application_data.accounts[local.environment].api_server_port
      cpu                = local.application_data.accounts[local.environment].container_cpu
      memory             = local.application_data.accounts[local.environment].container_memory
      aws_region         = local.application_data.accounts[local.environment].aws_region
      container_version  = local.application_data.accounts[local.environment].container_version
      ccms_s3_bucket     = local.sftp_bc_bucket_name
      ORACLE_USERNAME    = "${data.aws_secretsmanager_secret_version.sftp_bc_secrets.arn}:ORACLE_USERNAME::"
      ORACLE_PASSWORD    = "${data.aws_secretsmanager_secret_version.sftp_bc_secrets.arn}:ORACLE_PASSWORD::"
      ORACLE_URL         = "${data.aws_secretsmanager_secret_version.sftp_bc_secrets.arn}:ORACLE_URL::"
      SLACK_WEBHOOK      = "${data.aws_secretsmanager_secret_version.sftp_bc_secrets.arn}:SLACK_WEBHOOK::"
      ENABLE_SWAGGER     = "${data.aws_secretsmanager_secret_version.sftp_bc_secrets.arn}:ENABLE_SWAGGER::"
      AUTHORIZED_CLIENTS = "${data.aws_secretsmanager_secret_version.sftp_bc_secrets.arn}:AUTHORIZED_CLIENTS::"
      AUTHORIZED_ROLES   = "${data.aws_secretsmanager_secret_version.sftp_bc_secrets.arn}:AUTHORIZED_ROLES::"
      UNPROTECTED_URIS   = "${data.aws_secretsmanager_secret_version.sftp_bc_secrets.arn}:UNPROTECTED_URIS::"
    }
  )

  tags = merge(local.tags,
    { Name = lower(format("%s-sftp-bc-%s-task", local.application_name, local.environment)) }
  )
}

# ECS Service
resource "aws_ecs_service" "sftp_bc_ecs_service" {
  name            = "${local.application_name}-sftp-bc-service"
  cluster         = aws_ecs_cluster.main_cluster.id
  task_definition = aws_ecs_task_definition.sftp_bc_task_definition.arn
  desired_count   = local.application_data.accounts[local.environment].app_count
  launch_type     = "FARGATE"

  health_check_grace_period_seconds = 120
  lifecycle {
    ignore_changes = [
      task_definition
    ]
  }

  network_configuration {
    security_groups = [aws_security_group.cluster_fargate_sg.id]
    subnets         = data.aws_subnets.shared-private.ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sftp_bc_target_group.arn
    container_name   = local.application_data.accounts[local.environment].app_name
    container_port   = local.application_data.accounts[local.environment].api_server_port
  }

  depends_on = [
    aws_lb_listener.sftp_bc_listener,
    aws_iam_role_policy_attachment.bc_ecs_task_execution_role
  ]
}

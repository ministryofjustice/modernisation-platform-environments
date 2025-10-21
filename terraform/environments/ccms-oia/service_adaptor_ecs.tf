
# Task Definition for CCMS Service Adaptor

resource "aws_ecs_task_definition" "ecs_adaptor_task_definition" {
  family             = "${local.adaptor_app_name}-task"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  network_mode       = "bridge"
  requires_compatibilities = [
    "EC2",
  ]
  cpu    = local.application_data.accounts[local.environment].adaptor_container_cpu
  memory = local.application_data.accounts[local.environment].adaptor_container_memory

  container_definitions = templatefile(
    "${path.module}/templates/task_definition_service_adaptor.json.tpl",
    {
      adaptor_app_name                          = local.adaptor_app_name
      adaptor_ecr_repo                          = local.application_data.accounts[local.environment].adaptor_ecr_repo
      adaptor_server_port                       = local.application_data.accounts[local.environment].adaptor_server_port
      aws_region                                = local.application_data.accounts[local.environment].aws_region
      adaptor_spring_profile                    = local.application_data.accounts[local.environment].adaptor_spring_profile
      container_version                         = local.application_data.accounts[local.environment].adaptor_container_version
      client_opa12assess_means_address          = local.application_data.accounts[local.environment].client_opa12assess_means_address
      client_opa12assess_billing_address        = local.application_data.accounts[local.environment].client_opa12assess_billing_address
      client_opa12assess_security_user_name     = "${aws_secretsmanager_secret.service_adaptor_secrets.arn}:client_opa12assess_security_user_name::"
      client_opa12assess_security_user_password = "${aws_secretsmanager_secret.service_adaptor_secrets.arn}:client_opa12assess_security_user_password::"
      server_opa10assess_security_user_name     = "${aws_secretsmanager_secret.service_adaptor_secrets.arn}:server_opa10assess_security_user_name::"
      server_opa10assess_security_user_password = "${aws_secretsmanager_secret.service_adaptor_secrets.arn}:server_opa10assess_security_user_password::"
    }
  )

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-task", local.adaptor_app_name, local.environment)) }
  )
}

# ECS Service for adaptor

resource "aws_ecs_service" "ecs_adaptor_service" {
  name            = local.adaptor_app_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.ecs_adaptor_task_definition.arn
  desired_count   = local.application_data.accounts[local.environment].adaptor_app_count
  launch_type     = "EC2"

  health_check_grace_period_seconds = 300

  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.adaptor_target_group.id
    container_name   = "${local.adaptor_app_name}-container"
    container_port   = local.application_data.accounts[local.environment].adaptor_server_port
  }

  depends_on = [
    aws_lb_listener.adaptor_listener,
    aws_iam_role_policy_attachment.ecs_task_execution_role,
  ]

}

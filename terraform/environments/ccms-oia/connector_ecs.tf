
# Task Definition for Connector

resource "aws_ecs_task_definition" "ecs_connector_task_definition" {
  family             = "${local.connector_app_name}-task"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.connector_ecs_task_role.arn
  network_mode       = "bridge"
  requires_compatibilities = [
    "EC2",
  ]
  cpu    = local.application_data.accounts[local.environment].connector_container_cpu
  memory = local.application_data.accounts[local.environment].connector_container_memory

  container_definitions = templatefile(
    "${path.module}/templates/task_definition_connector.json.tpl",
    {
      connector_app_name                           = local.connector_app_name
      connector_ecr_repo                           = local.application_data.accounts[local.environment].connector_ecr_repo
      connector_server_port                        = local.application_data.accounts[local.environment].connector_server_port
      aws_region                                   = local.application_data.accounts[local.environment].aws_region
      spring_profiles_active                       = local.application_data.accounts[local.environment].spring_profiles_active
      container_version                            = local.application_data.accounts[local.environment].connector_container_version
      ccms_soa_soapHeaderUserPassword              = "${aws_secretsmanager_secret.connector_secrets.arn}:ccms_soa_soapHeaderUserPassword::"
      ccms_soa_soapHeaderUserName                  = "${aws_secretsmanager_secret.connector_secrets.arn}:ccms_soa_soapHeaderUserName::"
      ccms_connector_service_userid                = "${aws_secretsmanager_secret.connector_secrets.arn}:ccms_connector_service_userid::"
      ccms_connector_service_password              = "${aws_secretsmanager_secret.connector_secrets.arn}:ccms_connector_service_password::"
      aws_endpoint                                 = local.application_data.accounts[local.environment].aws_endpoint
      ccms_s3_documents                            = local.application_data.accounts[local.environment].ccms_s3_documents
      client_opa12assess_security_user_name        = "${aws_secretsmanager_secret.connector_secrets.arn}:client_opa12assess_security_user_name::"
      client_opa12assess_security_user_password    = "${aws_secretsmanager_secret.connector_secrets.arn}:client_opa12assess_security_user_password::"
      ccms_soa_url_ebsReferenceDataEndpoint        = local.application_data.accounts[local.environment].ccms_soa_url_ebsReferenceDataEndpoint
      ccms_pui_connector_assessservice_url_means   = local.application_data.accounts[local.environment].ccms_pui_connector_assessservice_url_means
      ccms_pui_connector_assessservice_url_merits  = local.application_data.accounts[local.environment].ccms_pui_connector_assessservice_url_merits
      ccms_pui_connector_assessservice_url_billing = local.application_data.accounts[local.environment].ccms_pui_connector_assessservice_url_billing
      ccms_pui_connector_answerservice_url_means   = local.application_data.accounts[local.environment].ccms_pui_connector_answerservice_url_means
      ccms_pui_connector_answerservice_url_merits  = local.application_data.accounts[local.environment].ccms_pui_connector_answerservice_url_merits
      ccms_pui_connector_answerservice_url_billing = local.application_data.accounts[local.environment].ccms_pui_connector_answerservice_url_billing
      spring_datasource_url                        = "${aws_secretsmanager_secret.connector_secrets.arn}:spring_datasource_url::"
      spring_datasource_username                   = "${aws_secretsmanager_secret.connector_secrets.arn}:spring_datasource_username::"
      spring_datasource_password                   = "${aws_secretsmanager_secret.connector_secrets.arn}:spring_datasource_password::"
      environment_connector                        = local.application_data.accounts[local.environment].connector_dns_name
      logging_level_root                           = local.application_data.accounts[local.environment].logging_level_root
      logging_level_com_ezgov_model                = local.application_data.accounts[local.environment].logging_level_com_ezgov_model
      logging_level_com_ezgov_opa                  = local.application_data.accounts[local.environment].logging_level_com_ezgov_opa
      logging_level_oracle_ocs_opa_laa             = local.application_data.accounts[local.environment].logging_level_oracle_ocs_opa_laa
      logging_level_uk_gov_laa_opa                 = local.application_data.accounts[local.environment].logging_level_uk_gov_laa_opa
      opa_security_password                        = "${aws_secretsmanager_secret.connector_secrets.arn}:opa_security_password::"
    }
  )

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-task", local.connector_app_name, local.environment)) }
  )
}

# ECS Service for Connector

resource "aws_ecs_service" "ecs_connector_service" {
  name            = local.connector_app_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.ecs_connector_task_definition.arn
  desired_count   = local.application_data.accounts[local.environment].connector_app_count
  launch_type     = "EC2"

  health_check_grace_period_seconds = 300

    lifecycle {
      ignore_changes = [
        task_definition
      ]
    }

  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.connector_target_group.id
    container_name   = "${local.connector_app_name}-container"
    container_port   = local.application_data.accounts[local.environment].connector_server_port
  }

  depends_on = [
    aws_lb_listener.connector_listener,
    aws_iam_role_policy_attachment.ecs_task_execution_role,
  ]

}

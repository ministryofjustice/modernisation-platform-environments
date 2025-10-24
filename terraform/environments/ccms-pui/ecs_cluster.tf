# ECS Cluster

resource "aws_ecs_cluster" "main" {
  name = "${local.application_name}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.capacity-provider.name]
}

# ECS Task Definition


resource "aws_ecs_task_definition" "pui" {
  family             = "${local.application_name}-task"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  network_mode       = "awsvpc"
  requires_compatibilities = [
    "EC2",
  ]
  cpu    = local.application_data.accounts[local.environment].container_cpu
  memory = local.application_data.accounts[local.environment].container_memory

  container_definitions = templatefile(
    "${path.module}/templates/task_definition_pui.json.tpl",
    {
      app_name                                                      = local.application_name
      app_image                                                     = local.application_data.accounts[local.environment].app_image
      pui_server_port                                               = local.application_data.accounts[local.environment].pui_server_port
      aws_region                                                    = local.application_data.accounts[local.environment].aws_region
      container_version                                             = local.application_data.accounts[local.environment].container_version
      spring_profiles_active                                        = local.application_data.accounts[local.environment].spring_profiles_active
      spring_datasource_username                                    = "${aws_secretsmanager_secret.pui_secrets.arn}:spring_datasource_username::"
      spring_datasource_password                                    = "${aws_secretsmanager_secret.pui_secrets.arn}:spring_datasource_password::"
      spring_datasource_url                                         = "${aws_secretsmanager_secret.pui_secrets.arn}:spring_datasource_url::"
      idp_cert                                                      = "${aws_secretsmanager_secret.pui_secrets.arn}:idp_cert::"
      spcert                                                        = "${aws_secretsmanager_secret.pui_secrets.arn}:spcert::"
      spprivatekey                                                  = "${aws_secretsmanager_secret.pui_secrets.arn}:spprivatekey::"
      idpLogoutUrl                                                  = local.application_data.accounts[local.environment].idpLogoutUrl
      idpMetadataUrl                                                = "${aws_secretsmanager_secret.pui_secrets.arn}:idpMetadataUrl::"
      loginUrl                                                      = "${aws_secretsmanager_secret.pui_secrets.arn}:loginUrl::"
      postcodeApiUrl                                                = "${aws_secretsmanager_secret.pui_secrets.arn}:postcodeApiUrl::"
      postcodeApiKey                                                = "${aws_secretsmanager_secret.pui_secrets.arn}:postcodeApiKey::"
      aws_endpoint                                                  = local.application_data.accounts[local.environment].aws_endpoint
      ccms_s3_documents                                             = local.application_data.accounts[local.environment].ccms_s3_documents
      ccms_pui_feedback_url                                         = local.application_data.accounts[local.environment].ccms_pui_feedback_url
      ccms_pui_owd_return_url                                       = local.application_data.accounts[local.environment].ccms_pui_owd_return_url
      ccms_soa_url_opaBillingAssessmentEndpoint                     = local.application_data.accounts[local.environment].ccms_soa_url_opaBillingAssessmentEndpoint
      ccms_soa_url_opaPOAAssessmentEndpoint                         = local.application_data.accounts[local.environment].ccms_soa_url_opaPOAAssessmentEndpoint
      ccms_soa_url_ebsClientEndpoint                                = local.application_data.accounts[local.environment].ccms_soa_url_ebsClientEndpoint
      ccms_soa_url_ebsCaseEndpoint                                  = local.application_data.accounts[local.environment].ccms_soa_url_ebsCaseEndpoint
      ccms_soa_url_ebsAddressEndpoint                               = local.application_data.accounts[local.environment].ccms_soa_url_ebsAddressEndpoint
      ccms_soa_url_ebsReferenceDataEndpoint                         = local.application_data.accounts[local.environment].ccms_soa_url_ebsReferenceDataEndpoint
      ccms_soa_url_ebsContractDetailsEndpoint                       = local.application_data.accounts[local.environment].ccms_soa_url_ebsContractDetailsEndpoint
      ccms_soa_url_ebsProviderRequestEndpoint                       = local.application_data.accounts[local.environment].ccms_soa_url_ebsProviderRequestEndpoint
      ccms_soa_url_ebsStatementOfAccountEndpoint                    = local.application_data.accounts[local.environment].ccms_soa_url_ebsStatementOfAccountEndpoint
      ccms_soa_url_ebsNotificationEndpoint                          = local.application_data.accounts[local.environment].ccms_soa_url_ebsNotificationEndpoint
      ccms_soa_url_ebsDocumentEndpoint                              = local.application_data.accounts[local.environment].ccms_soa_url_ebsDocumentEndpoint
      ccms_soa_url_ebsCreateInvoiceEndpoint                         = local.application_data.accounts[local.environment].ccms_soa_url_ebsCreateInvoiceEndpoint
      ccms_soa_url_ebsCoverSheetEndpoint                            = local.application_data.accounts[local.environment].ccms_soa_url_ebsCoverSheetEndpoint
      ccms_soa_url_ebsCommonOrgEndpoint                             = local.application_data.accounts[local.environment].ccms_soa_url_ebsCommonOrgEndpoint
      ccms_soa_url_ebsPrintInvoiceEndpoint                          = local.application_data.accounts[local.environment].ccms_soa_url_ebsPrintInvoiceEndpoint
      ccms_soa_url_ebsGetInvoiceDetailsEndpoint                     = local.application_data.accounts[local.environment].ccms_soa_url_ebsGetInvoiceDetailsEndpoint
      ccms_soa_url_ebsUpdateUserEndpoint                            = local.application_data.accounts[local.environment].ccms_soa_url_ebsUpdateUserEndpoint
      ccms_soa_soapHeaderUserPassword                               = "${aws_secretsmanager_secret.pui_secrets.arn}:ccms_soa_soapHeaderUserPassword::"
      ccms_soa_soapHeaderUserName                                   = "${aws_secretsmanager_secret.pui_secrets.arn}:ccms_soa_soapHeaderUserName::"
      user_management_api_access_token                              = "${aws_secretsmanager_secret.pui_secrets.arn}:user_management_api_access_token::"
      user_management_api_hostname                                  = "${aws_secretsmanager_secret.pui_secrets.arn}:user_management_api_hostname::"
      entra_custom_user_id_claim                                    = local.application_data.accounts[local.environment].entra_custom_user_id_claim
      is_silas_enabled                                              = local.application_data.accounts[local.environment].is_silas_enabled
      idpIdentityID                                                 = "${aws_secretsmanager_secret.pui_secrets.arn}:idpIdentityID::"
      IdpSamlMockEnabled                                            = local.application_data.accounts[local.environment].IdpSamlMockEnabled
      SpEntityId                                                    = "${aws_secretsmanager_secret.pui_secrets.arn}:SpEntityId::"
      SpEntityUrl                                                   = "${aws_secretsmanager_secret.pui_secrets.arn}:SpEntityUrl::"
      opa_security_password                                         = "${aws_secretsmanager_secret.pui_secrets.arn}:opa_security_password::"
      opa12_assess_service_servlet                                  = local.application_data.accounts[local.environment].opa12_assess_service_servlet
      ccms_owd_rulebase_baseurl                                     = local.application_data.accounts[local.environment].ccms_owd_rulebase_baseurl
      ccms_pui_av_port                                              = local.application_data.accounts[local.environment].ccms_pui_av_port
      ccms_pui_av_host                                              = local.application_data.accounts[local.environment].ccms_pui_av_host
      ccms_pui_av_socketTimeout                                     = local.application_data.accounts[local.environment].ccms_pui_av_socketTimeout
      ccms_pui_av_scannerEnabled                                    = local.application_data.accounts[local.environment].ccms_pui_av_scannerEnabled
      ccms_pui_auditLogin_enabled                                   = local.application_data.accounts[local.environment].ccms_pui_auditLogin_enabled
      logging_level_root                                            = local.application_data.accounts[local.environment].logging_level_root
      logging_level_com_ezgov                                       = local.application_data.accounts[local.environment].logging_level_com_ezgov
      logging_level_com_legalservices                               = local.application_data.accounts[local.environment].logging_level_com_legalservices
      logging_level_uk_gov_laa_opa                                  = local.application_data.accounts[local.environment].logging_level_uk_gov_laa_opa
      logging_level_com_ezgov_roof_view_vim_control_BundleAwareText = local.application_data.accounts[local.environment].logging_level_com_ezgov_roof_view_vim_control_BundleAwareText
      logging_level_root                                            = local.application_data.accounts[local.environment].logging_level_root
    }
  )

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-task", local.application_name, local.environment)) }
  )
}

# ECS Service

resource "aws_ecs_service" "pui" {
  name            = local.application_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.pui.arn
  desired_count   = local.application_data.accounts[local.environment].app_count
  launch_type     = "EC2"

  health_check_grace_period_seconds = 120
  #   lifecycle {
  #     ignore_changes = [
  #       task_definition
  #     ]
  #   }
  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  network_configuration {
    security_groups = [aws_security_group.ecs_tasks_pui.id]
    subnets         = data.aws_subnets.shared-private.ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.pui_target_group.id
    container_name   = local.application_name
    container_port   = local.application_data.accounts[local.environment].pui_server_port
  }

  depends_on = [
    aws_lb_listener.pui,
    aws_iam_role_policy_attachment.ecs_task_execution_role,
    aws_autoscaling_group.cluster-scaling-group
  ]
}

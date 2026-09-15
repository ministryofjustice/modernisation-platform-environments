module "ecs_cluster" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/b08a04f9346b56b005fdff6fcd595dc04a60fb8a
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ecs-cluster?ref=b08a04f9346b56b005fdff6fcd595dc04a60fb8a"

  cluster_name = "${local.component_name}-${local.env_label}-cluster"
  tags         = local.tags

  capacity_providers = {
    ec2 = {
      instance_type         = local.application_data.accounts[local.environment].ec2_instance_type
      image_id              = local.application_data.accounts[local.environment].ami_image_id
      min_size              = local.application_data.accounts[local.environment].ec2_min_capacity
      max_size              = local.application_data.accounts[local.environment].ec2_max_capacity
      desired_capacity      = local.application_data.accounts[local.environment].ec2_desired_capacity
      root_volume_size      = local.application_data.accounts[local.environment].root_volume_size
      instance_profile_name = aws_iam_instance_profile.ecs_ec2.name
      security_group_ids    = [aws_security_group.cluster_ec2.id]
      subnet_ids            = data.aws_subnets.shared-private.ids
      ebs_encrypted         = true
      kms_key_id            = data.aws_kms_key.ebs_shared.arn
      user_data             = base64encode(templatefile("${path.module}/templates/user-data.sh", {
        cluster_name       = "${local.component_name}-${local.env_label}-cluster"
        efs_id             = module.efs.file_system_id
        deploy_environment = local.environment
      }))
    }
  }
}

module "ecs_service_opahub" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/b08a04f9346b56b005fdff6fcd595dc04a60fb8a
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ecs-service?ref=b08a04f9346b56b005fdff6fcd595dc04a60fb8a"

  name               = "${local.opahub_name}-${local.env_label}"
  cluster_id         = module.ecs_cluster.cluster_id
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  desired_count      = local.application_data.accounts[local.environment].ec2_desired_capacity
  cpu                = local.application_data.accounts[local.environment].opa_container_cpu
  memory             = local.application_data.accounts[local.environment].opa_container_memory
  tags               = local.tags

  health_check_grace_period_seconds = 300

  volumes = [{
    name           = "opa_volume"
    file_system_id = module.efs.file_system_id
  }]

  container_definitions = templatefile("${path.module}/templates/task_definition_opahub.json.tpl", {
    app_name          = local.opahub_name
    app_image         = local.application_data.accounts[local.environment].opa_app_image
    container_version = local.application_data.accounts[local.environment].opa_container_version
    server_port       = local.application_data.accounts[local.environment].opa_server_port
    aws_region        = data.aws_region.current.region
    log_group_name    = aws_cloudwatch_log_group.opahub.name
    db_host           = module.rds.db_endpoint
    wl_mem_args       = local.application_data.accounts[local.environment].wl_mem_args
    create_database   = local.application_data.accounts[local.environment].create_database
    opahub_password   = "${aws_secretsmanager_secret.opahub.arn}:opahub_password::"
    db_user           = "${aws_secretsmanager_secret.opahub.arn}:db_user::"
    db_password       = "${aws_secretsmanager_secret.opahub.arn}:db_password::"
    wl_user           = "${aws_secretsmanager_secret.opahub.arn}:wl_user::"
    wl_password       = "${aws_secretsmanager_secret.opahub.arn}:wl_password::"
    secret_key        = "${aws_secretsmanager_secret.opahub.arn}:secret_key::"
  })

  load_balancer = {
    target_group_arn = module.alb_opahub.target_group_arn
    container_name   = "${local.opahub_name}-container"
    container_port   = local.application_data.accounts[local.environment].opa_server_port
  }

  depends_on = [
    module.alb_opahub,
    aws_iam_role_policy_attachment.ecs_task_execution,
    module.ecs_cluster,
    module.efs,
  ]
}

module "ecs_service_connector" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/b08a04f9346b56b005fdff6fcd595dc04a60fb8a
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ecs-service?ref=b08a04f9346b56b005fdff6fcd595dc04a60fb8a"

  name               = "${local.connector_name}-${local.env_label}"
  cluster_id         = module.ecs_cluster.cluster_id
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.connector_task.arn
  desired_count      = local.application_data.accounts[local.environment].connector_desired_count
  cpu                = local.application_data.accounts[local.environment].connector_container_cpu
  memory             = local.application_data.accounts[local.environment].connector_container_memory
  tags               = local.tags

  health_check_grace_period_seconds = 300

  container_definitions = templatefile("${path.module}/templates/task_definition_connector.json.tpl", {
    connector_app_name                           = local.connector_name
    connector_app_image                          = local.application_data.accounts[local.environment].connector_app_image
    container_version                            = local.application_data.accounts[local.environment].connector_container_version
    connector_server_port                        = local.application_data.accounts[local.environment].connector_server_port
    aws_region                                   = data.aws_region.current.region
    log_group_name                               = aws_cloudwatch_log_group.connector.name
    environment_connector                        = local.application_data.accounts[local.environment].environment_connector
    ccms_soa_url_ebsReferenceDataEndpoint        = local.application_data.accounts[local.environment].ccms_soa_url_ebsReferenceDataEndpoint
    ccms_pui_connector_assessservice_url_means   = local.application_data.accounts[local.environment].ccms_pui_connector_assessservice_url_means
    ccms_pui_connector_assessservice_url_merits  = local.application_data.accounts[local.environment].ccms_pui_connector_assessservice_url_merits
    ccms_pui_connector_assessservice_url_billing = local.application_data.accounts[local.environment].ccms_pui_connector_assessservice_url_billing
    ccms_pui_connector_answerservice_url_means   = local.application_data.accounts[local.environment].ccms_pui_connector_answerservice_url_means
    ccms_pui_connector_answerservice_url_merits  = local.application_data.accounts[local.environment].ccms_pui_connector_answerservice_url_merits
    ccms_pui_connector_answerservice_url_billing = local.application_data.accounts[local.environment].ccms_pui_connector_answerservice_url_billing
    aws_endpoint                                 = local.application_data.accounts[local.environment].aws_endpoint
    ccms_s3_documents                            = aws_s3_bucket.connector_docs.bucket
    logging_level_root                           = local.application_data.accounts[local.environment].logging_level_root
    logging_level_com_ezgov_model                = local.application_data.accounts[local.environment].logging_level_com_ezgov_model
    logging_level_com_ezgov_opa                  = local.application_data.accounts[local.environment].logging_level_com_ezgov_opa
    logging_level_oracle_ocs_opa_laa             = local.application_data.accounts[local.environment].logging_level_oracle_ocs_opa_laa
    logging_level_uk_gov_laa_opa                 = local.application_data.accounts[local.environment].logging_level_uk_gov_laa_opa
    spring_datasource_url                        = module.rds.db_endpoint
    ccms_soa_soapHeaderUserName                  = "${aws_secretsmanager_secret.connector.arn}:ccms_soa_soapHeaderUserName::"
    ccms_soa_soapHeaderUserPassword              = "${aws_secretsmanager_secret.connector.arn}:ccms_soa_soapHeaderUserPassword::"
    ccms_connector_service_userid                = "${aws_secretsmanager_secret.connector.arn}:ccms_connector_service_userid::"
    ccms_connector_service_password              = "${aws_secretsmanager_secret.connector.arn}:ccms_connector_service_password::"
    client_opa12assess_security_user_name        = "${aws_secretsmanager_secret.connector.arn}:client_opa12assess_security_user_name::"
    client_opa12assess_security_user_password    = "${aws_secretsmanager_secret.connector.arn}:client_opa12assess_security_user_password::"
    spring_datasource_username                   = "${aws_secretsmanager_secret.connector.arn}:spring_datasource_username::"
    spring_datasource_password                   = "${aws_secretsmanager_secret.connector.arn}:spring_datasource_password::"
    opa_security_password                        = "${aws_secretsmanager_secret.connector.arn}:opa_security_password::"
    ccms_bc_url                                  = "${aws_secretsmanager_secret.connector.arn}:ccms_bc_url::"
    ccms_bc_lscServiceName                       = "${aws_secretsmanager_secret.connector.arn}:ccms_bc_lscServiceName::"
    ccms_bc_clientOrgId                          = "${aws_secretsmanager_secret.connector.arn}:ccms_bc_clientOrgId::"
    ccms_bc_clientUserId                         = "${aws_secretsmanager_secret.connector.arn}:ccms_bc_clientUserId::"
  })

  load_balancer = {
    target_group_arn = module.alb_connector.target_group_arn
    container_name   = "${local.connector_name}-container"
    container_port   = local.application_data.accounts[local.environment].connector_server_port
  }

  depends_on = [
    module.alb_connector,
    aws_iam_role_policy_attachment.ecs_task_execution,
    module.ecs_cluster,
  ]
}

module "ecs_service_adaptor" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/b08a04f9346b56b005fdff6fcd595dc04a60fb8a
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ecs-service?ref=b08a04f9346b56b005fdff6fcd595dc04a60fb8a"

  name               = "${local.adaptor_name}-${local.env_label}"
  cluster_id         = module.ecs_cluster.cluster_id
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  desired_count      = local.application_data.accounts[local.environment].adaptor_desired_count
  cpu                = local.application_data.accounts[local.environment].adaptor_container_cpu
  memory             = local.application_data.accounts[local.environment].adaptor_container_memory
  tags               = local.tags

  health_check_grace_period_seconds = 300

  container_definitions = templatefile("${path.module}/templates/task_definition_service_adaptor.json.tpl", {
    adaptor_app_name                          = local.adaptor_name
    adaptor_app_image                         = local.application_data.accounts[local.environment].adaptor_app_image
    container_version                         = local.application_data.accounts[local.environment].adaptor_container_version
    adaptor_server_port                       = local.application_data.accounts[local.environment].adaptor_server_port
    aws_region                                = data.aws_region.current.region
    log_group_name                            = aws_cloudwatch_log_group.adaptor.name
    adaptor_spring_profile                    = local.application_data.accounts[local.environment].adaptor_spring_profile
    client_opa12assess_means_address          = local.application_data.accounts[local.environment].client_opa12assess_means_address
    client_opa12assess_billing_address        = local.application_data.accounts[local.environment].client_opa12assess_billing_address
    logging_config                            = local.application_data.accounts[local.environment].logging_config
    logging_level_root                        = local.application_data.accounts[local.environment].logging_level_root
    logging_level_uk_gov_justice_laa_ccms     = local.application_data.accounts[local.environment].logging_level_uk_gov_justice_laa_ccms
    client_opa12assess_security_user_name     = "${aws_secretsmanager_secret.adaptor.arn}:client_opa12assess_security_user_name::"
    client_opa12assess_security_user_password = "${aws_secretsmanager_secret.adaptor.arn}:client_opa12assess_security_user_password::"
    server_opa10assess_security_user_name     = "${aws_secretsmanager_secret.adaptor.arn}:server_opa10assess_security_user_name::"
    server_opa10assess_security_user_password = "${aws_secretsmanager_secret.adaptor.arn}:server_opa10assess_security_user_password::"
  })

  load_balancer = {
    target_group_arn = module.alb_adaptor.target_group_arn
    container_name   = "${local.adaptor_name}-container"
    container_port   = local.application_data.accounts[local.environment].adaptor_server_port
  }

  depends_on = [
    module.alb_adaptor,
    aws_iam_role_policy_attachment.ecs_task_execution,
    module.ecs_cluster,
  ]
}

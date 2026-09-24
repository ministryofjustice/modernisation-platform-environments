module "ecs_cluster" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/546ba54
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ecs-cluster?ref=546ba54"

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
    }
  }

  depends_on = [aws_kms_grant.autoscaling_ebs]
}

module "ecs_service" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/546ba54
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ecs-service?ref=546ba54"

  name               = "${local.component_name}-${local.env_label}"
  cluster_id         = module.ecs_cluster.cluster_id
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.pui_task.arn
  desired_count      = local.application_data.accounts[local.environment].app_count
  cpu                = local.application_data.accounts[local.environment].container_cpu
  memory             = local.application_data.accounts[local.environment].container_memory
  tags               = local.tags

  network_mode = "awsvpc"
  network_configuration = {
    subnets         = data.aws_subnets.shared-private.ids
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  container_definitions = templatefile("${path.module}/templates/task_definition.json.tpl", {
    app_name                                   = local.component_name
    app_image                                  = local.application_data.accounts[local.environment].app_image
    container_version                          = local.application_data.accounts[local.environment].container_version
    pui_server_port                            = local.application_data.accounts[local.environment].pui_server_port
    aws_region                                 = data.aws_region.current.region
    log_group_name                             = aws_cloudwatch_log_group.ecs.name
    pui_secret_arn                             = aws_secretsmanager_secret.pui.arn
    ccms_s3_documents                          = module.s3_docs.bucket.id
    aws_endpoint                               = "http://${module.s3_docs.bucket.id}"
    ccms_pui_feedback_url                      = "${local.owd_base_url}/startsession/FeedbackForm"
    ccms_pui_owd_return_url                    = "https://${local.pui_hostname}/civil"
    ccms_owd_rulebase_baseurl                  = local.owd_base_url
    opa12_assess_service_servlet               = "https://${local.connector_hostname}/service-tds/puiAssessService"
    ccms_soa_url_ebsClientEndpoint             = "${local.soa_services_url}/ClientServices/ClientServices_ep"
    ccms_soa_url_ebsCaseEndpoint               = "${local.soa_services_url}/CaseServices/CaseServices_ep"
    ccms_soa_url_ebsAddressEndpoint            = "${local.soa_services_url}/GetValidAddress/getvalidaddress_ep"
    ccms_soa_url_ebsReferenceDataEndpoint      = "${local.soa_services_url}/GetReferenceData/getreferencedata_ep"
    ccms_soa_url_ebsProviderRequestEndpoint    = "${local.soa_services_url}/SubmitProviderRequest/submitproviderrequest_ep"
    ccms_soa_url_ebsStatementOfAccountEndpoint = "${local.soa_services_url}/GetCaseStmtOfAccount/getcasestmtofaccount_ep"
    ccms_soa_url_ebsNotificationEndpoint       = "${local.soa_services_url}/NotificationServices/NotificationServices_ep"
    ccms_soa_url_ebsDocumentEndpoint           = "${local.soa_services_url}/DocumentServices/DocumentServices_ep"
    ccms_soa_url_ebsCreateInvoiceEndpoint      = "${local.soa_services_url}/CreateInvoice/createinvoice_client_ep"
    ccms_soa_url_ebsCoverSheetEndpoint         = "${local.soa_services_url}/GetCoverSheet/getcoversheet_ep"
    ccms_soa_url_ebsCommonOrgEndpoint          = "${local.soa_services_url}/GetCommonOrg/getcommonorg_ep"
    ccms_soa_url_ebsPrintInvoiceEndpoint       = "${local.soa_services_url}/PrintInvoice/printinvoice_client_ep"
    ccms_soa_url_ebsGetInvoiceDetailsEndpoint  = "${local.soa_services_url}/GetInvoiceDetails/bpelgetinvoicedetails_client_ep"
    ccms_soa_url_ebsUpdateUserEndpoint         = "${local.soa_services_url}/UpdateUser/UpdateUser_ep"
    ccms_pui_av_host                           = local.clamav_hostname
  })

  load_balancer = {
    target_group_arn = module.alb.target_group_arn
    container_name   = local.component_name
    container_port   = local.application_data.accounts[local.environment].pui_server_port
  }

  depends_on = [
    module.alb,
    aws_iam_role_policy_attachment.ecs_task_execution,
    module.ecs_cluster,
  ]
}

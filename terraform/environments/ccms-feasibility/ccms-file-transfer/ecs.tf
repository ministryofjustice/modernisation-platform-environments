module "ecs_cluster" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/337a98f
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ecs-cluster?ref=337a98f"

  cluster_name = local.cluster_name
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
      managed_scaling       = {}
      user_data = base64encode(templatefile("${path.module}/templates/user-data.sh", {
        cluster_name = local.cluster_name
      }))
    }
  }

  alarms = {
    topic_arn = data.aws_sns_topic.alerts.arn
  }
}

module "ecs_service" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/337a98f
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ecs-service?ref=337a98f"

  name       = "${local.fin_transfer_name}-${local.env_label}"
  cluster_id = module.ecs_cluster.cluster_id
  capacity_provider_strategy = [{
    capacity_provider = module.ecs_cluster.capacity_provider_names["ec2"]
    base              = 1
  }]
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.fin_transfer_task.arn
  desired_count      = local.application_data.accounts[local.environment].app_count
  cpu                = local.application_data.accounts[local.environment].container_cpu
  memory             = local.application_data.accounts[local.environment].container_memory
  tags               = local.tags

  network_mode = "awsvpc"
  network_configuration = {
    subnets         = data.aws_subnets.shared-private.ids
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  container_definitions = templatefile("${path.module}/templates/task_definition_api.json.tpl", {
    app_name                      = local.fin_transfer_name
    app_image                     = local.application_data.accounts[local.environment].app_image
    container_version             = local.application_data.accounts[local.environment].container_version
    api_server_port               = local.application_data.accounts[local.environment].api_server_port
    aws_region                    = data.aws_region.current.region
    log_group_name                = aws_cloudwatch_log_group.fin_transfer.name
    ccms_s3_bucket                = module.s3_bc_inbound.bucket.id
    logging_level_root            = local.application_data.accounts[local.environment].logging_level_root
    logging_level_uk_gov_laa_ccms = local.application_data.accounts[local.environment].logging_level_uk_gov_laa_ccms
    oracle_username               = "${aws_secretsmanager_secret.fin_transfer.arn}:ORACLE_USERNAME::"
    oracle_password               = "${aws_secretsmanager_secret.fin_transfer.arn}:ORACLE_PASSWORD::"
    oracle_url                    = "${aws_secretsmanager_secret.fin_transfer.arn}:ORACLE_URL::"
    slack_webhook                 = "${aws_secretsmanager_secret.fin_transfer.arn}:SLACK_WEBHOOK::"
    enable_swagger                = "${aws_secretsmanager_secret.fin_transfer.arn}:ENABLE_SWAGGER::"
    authorized_clients            = "${aws_secretsmanager_secret.fin_transfer.arn}:AUTHORIZED_CLIENTS::"
    authorized_roles              = "${aws_secretsmanager_secret.fin_transfer.arn}:AUTHORIZED_ROLES::"
    unprotected_uris              = "${aws_secretsmanager_secret.fin_transfer.arn}:UNPROTECTED_URIS::"
    oauth2_issuer_uri             = "${aws_secretsmanager_secret.fin_transfer.arn}:OAUTH2_ISSUER_URI::"
    oauth2_audience               = "${aws_secretsmanager_secret.fin_transfer.arn}:OAUTH2_AUDIENCE::"
    oauth2_roles                  = "${aws_secretsmanager_secret.fin_transfer.arn}:OAUTH2_ROLES::"
    oauth2_unprotected_uris       = "${aws_secretsmanager_secret.fin_transfer.arn}:OAUTH2_UNPROTECTED_URIS::"
    tls_keystore_password         = "${aws_secretsmanager_secret.fin_transfer.arn}:TLS_KEYSTORE_PASSWORD::"
  })

  # The API terminates TLS itself; the ALB re-encrypts to the container port
  load_balancer = {
    target_group_arn = module.alb.target_group_arn
    container_name   = "${local.fin_transfer_name}-container"
    container_port   = local.application_data.accounts[local.environment].api_server_port
  }

  alarms = {
    topic_arn = data.aws_sns_topic.alerts.arn
  }

  depends_on = [
    module.alb,
    aws_iam_role_policy_attachment.ecs_task_execution,
    module.ecs_cluster,
  ]
}

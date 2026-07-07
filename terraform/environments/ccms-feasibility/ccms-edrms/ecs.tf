module "ecs_cluster" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/11c2b289779bfa4e0c02ca7d4b31a0092f2124e1
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ecs-cluster?ref=11c2b289779bfa4e0c02ca7d4b31a0092f2124e1"

  cluster_name = "${local.component_name}-${local.env_label}-cluster"
  tags         = local.tags

  capacity_providers = {
    default = {
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
}

module "ecs_service" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/11c2b289779bfa4e0c02ca7d4b31a0092f2124e1
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ecs-service?ref=11c2b289779bfa4e0c02ca7d4b31a0092f2124e1"

  name               = "${local.component_name}-${local.env_label}"
  cluster_id         = module.ecs_cluster.cluster_id
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  desired_count      = local.application_data.accounts[local.environment].app_count
  cpu                = local.application_data.accounts[local.environment].container_cpu
  memory             = local.application_data.accounts[local.environment].container_memory
  tags               = local.tags

  container_definitions = templatefile("${path.module}/templates/task_definition.json.tpl", {
    app_name                      = local.component_name
    app_image                     = local.application_data.accounts[local.environment].app_image
    container_version             = local.application_data.accounts[local.environment].container_version
    edrms_server_port             = local.application_data.accounts[local.environment].edrms_server_port
    aws_region                    = data.aws_region.current.region
    spring_profiles_active        = local.application_data.accounts[local.environment].spring_profiles_active
    edrms_secret_arn              = aws_secretsmanager_secret.edrms.arn
    target_northgate_hub_dime_url = local.application_data.accounts[local.environment].target_northgate_hub_dime_url
    northgate_timeout             = local.application_data.accounts[local.environment].northgate_timeout
    spring_datasource_url         = module.rds.db_endpoint
    logging_level_root            = local.application_data.accounts[local.environment].logging_level_root
    log_group_name                = aws_cloudwatch_log_group.ecs.name
  })

  load_balancer = {
    target_group_arn = module.alb.target_group_arn
    container_name   = local.component_name
    container_port   = local.application_data.accounts[local.environment].edrms_server_port
  }

  depends_on = [
    module.alb,
    aws_iam_role_policy_attachment.ecs_task_execution,
    module.ecs_cluster,
  ]
}

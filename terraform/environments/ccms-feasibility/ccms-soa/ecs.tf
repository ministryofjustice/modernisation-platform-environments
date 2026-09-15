# Inbound/outbound file-exchange S3 buckets, already built in this account by ccms-ebs
data "aws_s3_bucket" "inbound" {
  bucket = "${local.application_name}-inbound"
}

data "aws_s3_bucket" "outbound" {
  bucket = "${local.application_name}-outbound"
}

module "ecs_cluster" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/c20a9496c059d1302b3bb7c3bd0dcd6792a0c8e0
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ecs-cluster?ref=c20a9496c059d1302b3bb7c3bd0dcd6792a0c8e0"

  cluster_name = "${local.component_name}-${local.env_label}-cluster"
  tags         = local.tags

  capacity_providers = {
    admin = {
      instance_type         = local.application_data.accounts[local.environment].admin_ec2_instance_type
      image_id              = local.application_data.accounts[local.environment].admin_ami_image_id
      min_size              = local.application_data.accounts[local.environment].admin_ec2_min_capacity
      max_size              = local.application_data.accounts[local.environment].admin_ec2_max_capacity
      desired_capacity      = local.application_data.accounts[local.environment].admin_ec2_desired_capacity
      root_volume_size      = local.application_data.accounts[local.environment].root_volume_size
      instance_profile_name = aws_iam_instance_profile.ecs_ec2.name
      security_group_ids    = [aws_security_group.cluster_ec2.id]
      subnet_ids            = data.aws_subnets.shared-private.ids
      ebs_encrypted         = true
      kms_key_id            = data.aws_kms_key.ebs_shared.arn
      user_data = base64encode(templatefile("${path.module}/templates/user-data.sh", {
        cluster_name    = "${local.component_name}-${local.env_label}-cluster"
        efs_id          = module.efs.file_system_id
        server          = "admin"
        inbound_bucket  = data.aws_s3_bucket.inbound.id
        outbound_bucket = data.aws_s3_bucket.outbound.id
      }))
    }
    managed = {
      instance_type         = local.application_data.accounts[local.environment].managed_ec2_instance_type
      image_id              = local.application_data.accounts[local.environment].managed_ami_image_id
      min_size              = local.application_data.accounts[local.environment].managed_ec2_min_capacity
      max_size              = local.application_data.accounts[local.environment].managed_ec2_max_capacity
      desired_capacity      = local.application_data.accounts[local.environment].managed_ec2_desired_capacity
      root_volume_size      = local.application_data.accounts[local.environment].root_volume_size
      instance_profile_name = aws_iam_instance_profile.ecs_ec2.name
      security_group_ids    = [aws_security_group.cluster_ec2.id]
      subnet_ids            = data.aws_subnets.shared-private.ids
      ebs_encrypted         = true
      kms_key_id            = data.aws_kms_key.ebs_shared.arn
      user_data = base64encode(templatefile("${path.module}/templates/user-data.sh", {
        cluster_name    = "${local.component_name}-${local.env_label}-cluster"
        efs_id          = module.efs.file_system_id
        server          = "managed"
        inbound_bucket  = data.aws_s3_bucket.inbound.id
        outbound_bucket = data.aws_s3_bucket.outbound.id
      }))
    }
  }
}

module "ecs_service_admin" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/bf7ac1c
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ecs-service?ref=bf7ac1c"

  name               = "${local.component_name}-admin-${local.env_label}"
  cluster_id         = module.ecs_cluster.cluster_id
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  desired_count      = local.application_data.accounts[local.environment].admin_app_count
  cpu                = local.application_data.accounts[local.environment].admin_container_cpu
  memory             = local.application_data.accounts[local.environment].admin_container_memory
  tags               = local.tags

  network_mode = "awsvpc"
  network_configuration = {
    subnets         = data.aws_subnets.shared-private.ids
    security_groups = [aws_security_group.ecs_tasks_admin.id]
  }

  health_check_grace_period_seconds = 1800

  placement_constraints = [{
    type       = "memberOf"
    expression = "attribute:server == admin"
  }]

  volumes = [{
    name           = "soa_volume"
    file_system_id = module.efs.file_system_id
  }]

  container_definitions = templatefile("${path.module}/templates/task_definition_admin.json.tpl", {
    app_name             = local.component_name
    app_image            = local.application_data.accounts[local.environment].admin_app_image
    container_version    = local.application_data.accounts[local.environment].admin_container_version
    admin_ssl_port       = local.application_data.accounts[local.environment].admin_ssl_port
    aws_region           = data.aws_region.current.region
    log_group_name       = aws_cloudwatch_log_group.admin.name
    db_instance_endpoint = module.rds.db_endpoint
    db_user              = local.application_data.accounts[local.environment].soa_db_user
    db_role              = local.application_data.accounts[local.environment].soa_db_role
    as_hostname          = aws_route53_record.admin.fqdn
    wl_admin_mem_args    = local.application_data.accounts[local.environment].admin_wl_mem_args
    run_rcu              = local.application_data.accounts[local.environment].admin_run_rcu_bootstrap
    xxsoa_ds_url         = "jdbc:oracle:thin:@//${data.aws_db_instance.edrms_tds.address}:${data.aws_db_instance.edrms_tds.port}/EDRMSTDS"
    xxsoa_ds_username    = "XXSOA"
    pui_user             = local.application_data.accounts[local.environment].admin_pui_user
    caab_user            = local.application_data.accounts[local.environment].admin_caab_user
    apply_user           = local.application_data.accounts[local.environment].admin_apply_user
    keystore_secret_id   = aws_secretsmanager_secret.soa.name
    soa_secret_arn       = aws_secretsmanager_secret.soa.arn
  })

  load_balancer = {
    target_group_arn = module.nlb_admin.target_group_arn
    container_name   = "${local.component_name}-admin"
    container_port   = local.application_data.accounts[local.environment].admin_ssl_port
  }

  depends_on = [
    module.nlb_admin,
    aws_iam_role_policy_attachment.ecs_task_execution,
    module.ecs_cluster,
    module.efs,
    module.rds,
  ]
}

module "ecs_service_managed" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/bf7ac1c
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ecs-service?ref=bf7ac1c"

  name               = "${local.component_name}-managed-${local.env_label}"
  cluster_id         = module.ecs_cluster.cluster_id
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  desired_count      = local.application_data.accounts[local.environment].managed_app_count
  cpu                = local.application_data.accounts[local.environment].managed_container_cpu
  memory             = local.application_data.accounts[local.environment].managed_container_memory
  tags               = local.tags

  network_mode = "awsvpc"
  network_configuration = {
    subnets         = data.aws_subnets.shared-private.ids
    security_groups = [aws_security_group.ecs_tasks_managed.id]
  }

  health_check_grace_period_seconds = 1800

  placement_constraints = [{
    type       = "memberOf"
    expression = "attribute:server == managed"
  }]

  volumes = [{
    name           = "soa_volume"
    file_system_id = module.efs.file_system_id
  }]

  host_volumes = [
    {
      name      = "inbound_volume"
      host_path = "/home/ec2-user/inbound"
    },
    {
      name      = "outbound_volume"
      host_path = "/home/ec2-user/outbound"
    },
  ]

  container_definitions = templatefile("${path.module}/templates/task_definition_managed.json.tpl", {
    app_name          = local.component_name
    app_image         = local.application_data.accounts[local.environment].managed_app_image
    container_version = local.application_data.accounts[local.environment].managed_container_version
    managed_ssl_port  = local.application_data.accounts[local.environment].managed_ssl_port
    admin_ssl_port    = local.application_data.accounts[local.environment].admin_ssl_port
    aws_region        = data.aws_region.current.region
    log_group_name    = aws_cloudwatch_log_group.managed.name
    admin_host        = aws_route53_record.admin.fqdn
    ms_hostname       = aws_route53_record.managed.fqdn
    wl_mem_args       = local.application_data.accounts[local.environment].managed_wl_mem_args
    soa_secret_arn    = aws_secretsmanager_secret.soa.arn
  })

  load_balancer = {
    target_group_arn = module.nlb_managed.target_group_arn
    container_name   = "${local.component_name}-managed"
    container_port   = local.application_data.accounts[local.environment].managed_ssl_port
  }

  depends_on = [
    module.nlb_managed,
    aws_iam_role_policy_attachment.ecs_task_execution,
    module.ecs_cluster,
    module.ecs_service_admin,
  ]
}

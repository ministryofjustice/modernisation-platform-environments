# ------------------------------------------------------------------------------
# ECS
# ------------------------------------------------------------------------------

module "mlra-ecs" {

  source = "./modules/ecs"

  subnet_set_name                = local.subnet_set_name
  vpc_all                        = local.vpc_all
  app_name                       = local.application_name
  container_instance_type        = local.application_data.accounts[local.environment].container_instance_type
  instance_type                  = local.application_data.accounts[local.environment].instance_type
  user_data                      = local.user_data
  key_name                       = local.application_data.accounts[local.environment].key_name
  task_definition                = local.task_definition
  ec2_desired_capacity           = local.application_data.accounts[local.environment].ec2_desired_capacity
  ec2_max_size                   = local.application_data.accounts[local.environment].ec2_max_size
  ec2_min_size                   = local.application_data.accounts[local.environment].ec2_min_size
  task_definition_volume         = local.application_data.accounts[local.environment].task_definition_volume
  network_mode                   = local.application_data.accounts[local.environment].network_mode
  server_port                    = local.application_data.accounts[local.environment].server_port
  app_count                      = local.application_data.accounts[local.environment].app_count
  ec2_ingress_rules              = local.ec2_ingress_rules
  ec2_egress_rules               = local.ec2_egress_rules
  lb_tg_arn                      = module.alb.target_group_arn
  tags_common                    = local.tags
  appscaling_min_capacity        = local.application_data.accounts[local.environment].appscaling_min_capacity
  appscaling_max_capacity        = local.application_data.accounts[local.environment].appscaling_max_capacity
  ec2_scaling_cpu_threshold      = local.application_data.accounts[local.environment].ec2_scaling_cpu_threshold
  ec2_scaling_mem_threshold      = local.application_data.accounts[local.environment].ec2_scaling_mem_threshold
  ecs_scaling_cpu_threshold      = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
  ecs_scaling_mem_threshold      = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
  region                         = local.application_data.accounts[local.environment].region
  account_number                 = local.environment_management.account_ids[terraform.workspace]
  maatdb_password_secret_name    = local.maatdb_password_secret_name
  app_master_password_name       = local.app_master_password_name
  app_salt_name                  = local.app_salt_name
  app_derivation_iterations_name = local.app_derivation_iterations_name
  gtm_id_secret_name             = local.gtm_id_secret_name
  infox_client_secret            = local.infox_client_secret_name
  ecs_target_capacity            = local.ecs_target_capacity
  environment                    = local.environment
  maatdb_rds_sec_group_id        = local.application_data.accounts[local.environment].maatdb_rds_sec_group_id
  alb_security_group_id          = local.alb_security_group_id
  maat_api_client_id_name        = local.maat_api_client_id_name
  maat_api_client_secret_name    = local.maat_api_client_secret_name
}

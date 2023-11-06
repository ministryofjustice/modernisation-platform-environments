locals {
  rds_url                      = "${aws_db_instance.rdsdb.address}"
  rds_user                     = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
  rds_port                     = "1433"
  rds_password                 = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
  source_db_url                = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
  source_db_user               = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
  source_db_password           = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
  container_definition_image   = "${aws_ecr_repository.app-ecr-repo.repository_url}:latest"
}

module "transport" {
  source                            = "./modules/tribunal"
  app_name                          = "transport"
  app_url                           = "transportappeals"
  sql_migration_path                = "../scripts/transport"
  app_db_name                       = "transport"
  app_db_login_name                 = "transport-app"
  app_source_db_name                = "Transport"
  app_rds_url                       = local.rds_url
  app_rds_user                      = local.rds_user
  app_rds_port                      = local.rds_port
  app_rds_password                  = local.rds_password
  app_source_db_url                 = local.source_db_url
  app_source_db_user                = local.source_db_user
  app_source_db_password            = local.source_db_password
  app_container_definition_image    = local.container_definition_image
  environment                       = local.environment
  application_data                  = local.application_data.accounts[local.environment]
  tags                              = local.tags
  dms_instance_arn                  = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn  
  task_definition_volume            = local.application_data.accounts[local.environment].task_definition_volume
  appscaling_min_capacity           = local.application_data.accounts[local.environment].appscaling_min_capacity
  appscaling_max_capacity           = local.application_data.accounts[local.environment].appscaling_max_capacity
  ecs_scaling_cpu_threshold         = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
  ecs_scaling_mem_threshold         = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
  app_count                         = local.application_data.accounts[local.environment].app_count  
  server_port                       = local.application_data.accounts[local.environment].server_port_1
  cluster_id                        = aws_ecs_cluster.tribunals_cluster.id
  cluster_name                      = aws_ecs_cluster.tribunals_cluster.name 
  vpc_shared_id                     = data.aws_vpc.shared.id 
  subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
  aws_acm_certificate_external      = aws_acm_certificate.external
}

module "appeals" {
  source                            = "./modules/tribunal"
  app_name                          = "appeals"
  app_url                           = "administrativeappeals"
  sql_migration_path                = "../scripts/administrative_appeals"
  app_db_name                       = "ossc"
  app_db_login_name                 = "ossc-app"
  app_source_db_name                = "Ossc"
  app_rds_url                       = local.rds_url
  app_rds_user                      = local.rds_user
  app_rds_port                      = local.rds_port
  app_rds_password                  = local.rds_password
  app_source_db_url                 = local.source_db_url
  app_source_db_user                = local.source_db_user
  app_source_db_password            = local.source_db_password
  app_container_definition_image    = local.container_definition_image
  environment                       = local.environment
  application_data                  = local.application_data.accounts[local.environment]
  tags                              = local.tags
  dms_instance_arn                  = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
  task_definition_volume            = local.application_data.accounts[local.environment].task_definition_volume
  appscaling_min_capacity           = local.application_data.accounts[local.environment].appscaling_min_capacity
  appscaling_max_capacity           = local.application_data.accounts[local.environment].appscaling_max_capacity
  ecs_scaling_cpu_threshold         = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
  ecs_scaling_mem_threshold         = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
  app_count                         = local.application_data.accounts[local.environment].app_count 
  server_port                       = local.application_data.accounts[local.environment].server_port_1
  cluster_id                        = aws_ecs_cluster.tribunals_cluster.id
  cluster_name                      = aws_ecs_cluster.tribunals_cluster.name
  vpc_shared_id                     = data.aws_vpc.shared.id 
  subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
  aws_acm_certificate_external      = aws_acm_certificate.external
}

/*module "ahmlr" {
  source                            = "./modules/tribunal"
  app_name                          = "ahmlr"
  app_url                           = "ahmlr"
  sql_migration_path                = "../scripts/administrative_appeals"
  app_db_name                       = "hmlands"
  app_db_login_name                 = "hmlands-app"
  app_source_db_name                = "hmlands"
  app_rds_url                       = local.rds_url
  app_rds_user                      = local.rds_user
  app_rds_port                      = local.rds_port
  app_rds_password                  = local.rds_password
  app_source_db_url                 = local.source_db_url
  app_source_db_user                = local.source_db_user
  app_source_db_password            = local.source_db_password
  environment                       = local.environment
  application_data                  = local.application_data.accounts[local.environment]
  tags                              = local.tags
  dms_instance_arn                  = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
  task_definition_volume            = local.application_data.accounts[local.environment].task_definition_volume
  appscaling_min_capacity           = local.application_data.accounts[local.environment].appscaling_min_capacity
  appscaling_max_capacity           = local.application_data.accounts[local.environment].appscaling_max_capacity
  ecs_scaling_cpu_threshold         = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
  ecs_scaling_mem_threshold         = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
  app_count                         = local.application_data.accounts[local.environment].app_count
  lb_tg_arn                         = aws_lb_target_group.tribunals_target_group.arn
  server_port                       = local.application_data.accounts[local.environment].server_port_1
  lb_listener                       = aws_lb_listener.tribunals_lb
  cluster_id                        = aws_ecs_cluster.tribunals_cluster.id
  cluster_name                      = aws_ecs_cluster.tribunals_cluster.name
}*/

# # module "care_standards" {
# #   source                = "./modules/care_standards"
# #   application_name      = "carestandards"
# # }

# # module "cicap" {
# #   source                = "./tribunals/cicap"
# #   application_name      = "cicap"
# # }

# # module "employment_appeals" {
# #   source                = "./modules/employment_appeals"
# #   application_name      = "eat"
# # }

# # module "finance_and_tax" {
# #   source                = "./modules/finance_and_tax"
# #   application_name      = "ftt"
# # }

# # module "immigartion_services" {
# #   source                = "./modules/immigartion_services"
# #   application_name      = "imset"
# # }

# # module "information_tribunal" {
# #   source                = "./modules/information_tribunal"
# #   application_name      = "it"
# # }

# # # module "lands_chamber" {
# # #   source                = "./modules/lands_chamber"
# # #   application_name      = "lands"
# # # }
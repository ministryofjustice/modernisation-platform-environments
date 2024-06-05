locals {
  rds_url                      = "${aws_db_instance.rdsdb.address}"
  rds_user                     = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
  rds_port                     = "1433"
  rds_password                 = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
  source_db_url                = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
  source_db_user               = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
  source_db_password           = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
  waf_arn                      = "${aws_wafv2_web_acl.tribunals_web_acl.arn}"
}

module "appeals" {
  is_ftp_app                        = false
  source                            = "./modules/tribunal"
  # The app_name needs to match the folder name in the volume
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
  documents_location                = "JudgmentFiles"
  waf_arn                           = local.waf_arn
}

module "ahmlr" {
  is_ftp_app                        = false
  source                            = "./modules/tribunal"
  app_name                          = "hmlands"
  app_url                           = "landregistrationdivision"
  sql_migration_path                = "../scripts/ahmlr"
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
  server_port                       = local.application_data.accounts[local.environment].server_port_1
  cluster_id                        = aws_ecs_cluster.tribunals_cluster.id
  cluster_name                      = aws_ecs_cluster.tribunals_cluster.name
  vpc_shared_id                     = data.aws_vpc.shared.id
  subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
  aws_acm_certificate_external      = aws_acm_certificate.external
  documents_location                = "Judgments"
  waf_arn                           = local.waf_arn
}

module "care_standards" {
  is_ftp_app                        = false
  source                            = "./modules/tribunal"
  app_name                          = "care-standards"
  app_url                           = "carestandards"
  sql_migration_path                = "../scripts/care_standards"
  app_db_name                       = "carestandards"
  app_db_login_name                 = "carestandards-app"
  app_source_db_name                = "carestandards"
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
  server_port                       = local.application_data.accounts[local.environment].server_port_1
  cluster_id                        = aws_ecs_cluster.tribunals_cluster.id
  cluster_name                      = aws_ecs_cluster.tribunals_cluster.name
  vpc_shared_id                     = data.aws_vpc.shared.id
  subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
  aws_acm_certificate_external      = aws_acm_certificate.external
  documents_location                = "Judgments"
  waf_arn                           = local.waf_arn
}

module "cicap" {
  is_ftp_app                        = false
  source                            = "./modules/tribunal"
  app_name                          = "cicap"
  app_url                           = "cicap"
  sql_migration_path                = "../scripts/cicap"
  app_db_name                       = "cicap"
  app_db_login_name                 = "cicap-app"
  app_source_db_name                = "cicap"
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
  server_port                       = local.application_data.accounts[local.environment].server_port_1
  cluster_id                        = aws_ecs_cluster.tribunals_cluster.id
  cluster_name                      = aws_ecs_cluster.tribunals_cluster.name
  vpc_shared_id                     = data.aws_vpc.shared.id
  subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
  aws_acm_certificate_external      = aws_acm_certificate.external
  documents_location                = "CaseFiles"
  waf_arn                           = local.waf_arn
}

module "employment_appeals" {
  is_ftp_app                        = false
  source                            = "./modules/tribunal"
  app_name                          = "employment-appeals"
  app_url                           = "employmentappeals"
  sql_migration_path                = "../scripts/employment_appeals"
  app_db_name                       = "eat"
  app_db_login_name                 = "eat-app"
  app_source_db_name                = "eat"
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
  server_port                       = local.application_data.accounts[local.environment].server_port_1
  cluster_id                        = aws_ecs_cluster.tribunals_cluster.id
  cluster_name                      = aws_ecs_cluster.tribunals_cluster.name
  vpc_shared_id                     = data.aws_vpc.shared.id
  subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
  aws_acm_certificate_external      = aws_acm_certificate.external
  documents_location                = "Public/Upload"
  waf_arn                           = local.waf_arn
}

# module "finance_and_tax" {
#   is_ftp_app                        = false
#   source                            = "./modules/tribunal"
#   app_name                          = "finance-and-tax"
#   app_url                           = "financeandtax"
#   sql_migration_path                = "../scripts/finance_and_tax"
#   app_db_name                       = "ftt"
#   app_db_login_name                 = "ftt-app"
#   app_source_db_name                = "ftt"
#   app_rds_url                       = local.rds_url
#   app_rds_user                      = local.rds_user
#   app_rds_port                      = local.rds_port
#   app_rds_password                  = local.rds_password
#   app_source_db_url                 = local.source_db_url
#   app_source_db_user                = local.source_db_user
#   app_source_db_password            = local.source_db_password
#   environment                       = local.environment
#   application_data                  = local.application_data.accounts[local.environment]
#   tags                              = local.tags
#   dms_instance_arn                  = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
#   task_definition_volume            = local.application_data.accounts[local.environment].task_definition_volume
#   appscaling_min_capacity           = local.application_data.accounts[local.environment].appscaling_min_capacity
#   appscaling_max_capacity           = local.application_data.accounts[local.environment].appscaling_max_capacity
#   ecs_scaling_cpu_threshold         = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
#   ecs_scaling_mem_threshold         = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
#   app_count                         = local.application_data.accounts[local.environment].app_count
#   server_port                       = local.application_data.accounts[local.environment].server_port_1
#   cluster_id                        = aws_ecs_cluster.tribunals_cluster.id
#   cluster_name                      = aws_ecs_cluster.tribunals_cluster.name
#   vpc_shared_id                     = data.aws_vpc.shared.id
#   subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
#   aws_acm_certificate_external      = aws_acm_certificate.external
#   documents_location                = "JudgmentFiles"
#   waf_arn                           = local.waf_arn
# }

# module "immigration_services" {
#   is_ftp_app                        = false
#   source                            = "./modules/tribunal"
#   app_name                          = "immigration-services"
#   app_url                           = "immigrationservices"
#   sql_migration_path                = "../scripts/immigration_services"
#   app_db_name                       = "imset"
#   app_db_login_name                 = "imset-app"
#   app_source_db_name                = "imset"
#   app_rds_url                       = local.rds_url
#   app_rds_user                      = local.rds_user
#   app_rds_port                      = local.rds_port
#   app_rds_password                  = local.rds_password
#   app_source_db_url                 = local.source_db_url
#   app_source_db_user                = local.source_db_user
#   app_source_db_password            = local.source_db_password
#   environment                       = local.environment
#   application_data                  = local.application_data.accounts[local.environment]
#   tags                              = local.tags
#   dms_instance_arn                  = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
#   task_definition_volume            = local.application_data.accounts[local.environment].task_definition_volume
#   appscaling_min_capacity           = local.application_data.accounts[local.environment].appscaling_min_capacity
#   appscaling_max_capacity           = local.application_data.accounts[local.environment].appscaling_max_capacity
#   ecs_scaling_cpu_threshold         = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
#   ecs_scaling_mem_threshold         = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
#   app_count                         = local.application_data.accounts[local.environment].app_count
#   server_port                       = local.application_data.accounts[local.environment].server_port_1
#   cluster_id                        = aws_ecs_cluster.tribunals_cluster.id
#   cluster_name                      = aws_ecs_cluster.tribunals_cluster.name
#   vpc_shared_id                     = data.aws_vpc.shared.id
#   subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
#   aws_acm_certificate_external      = aws_acm_certificate.external
#   documents_location                = "JudgmentFiles"
#   waf_arn                           = local.waf_arn
# }

# module "information_tribunal" {
#   is_ftp_app                        = false
#   source                            = "./modules/tribunal"
#   app_name                          = "information-tribunal"
#   app_url                           = "informationrights"
#   sql_migration_path                = "../scripts/information_tribunal"
#   app_db_name                       = "it"
#   app_db_login_name                 = "it-app"
#   app_source_db_name                = "it"
#   app_rds_url                       = local.rds_url
#   app_rds_user                      = local.rds_user
#   app_rds_port                      = local.rds_port
#   app_rds_password                  = local.rds_password
#   app_source_db_url                 = local.source_db_url
#   app_source_db_user                = local.source_db_user
#   app_source_db_password            = local.source_db_password
#   environment                       = local.environment
#   application_data                  = local.application_data.accounts[local.environment]
#   tags                              = local.tags
#   dms_instance_arn                  = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
#   task_definition_volume            = local.application_data.accounts[local.environment].task_definition_volume
#   appscaling_min_capacity           = local.application_data.accounts[local.environment].appscaling_min_capacity
#   appscaling_max_capacity           = local.application_data.accounts[local.environment].appscaling_max_capacity
#   ecs_scaling_cpu_threshold         = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
#   ecs_scaling_mem_threshold         = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
#   app_count                         = local.application_data.accounts[local.environment].app_count
#   server_port                       = local.application_data.accounts[local.environment].server_port_1
#   cluster_id                        = aws_ecs_cluster.tribunals_cluster.id
#   cluster_name                      = aws_ecs_cluster.tribunals_cluster.name
#   vpc_shared_id                     = data.aws_vpc.shared.id
#   subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
#   aws_acm_certificate_external      = aws_acm_certificate.external
#   documents_location                = "DBFiles"
#   waf_arn                           = local.waf_arn
# }

# module "lands_tribunal" {
#   is_ftp_app                        = false
#   source                            = "./modules/tribunal"
#   app_name                          = "lands-chamber"
#   app_url                           = "landschamber"
#   sql_migration_path                = "../scripts/lands_chamber"
#   app_db_name                       = "lands"
#   app_db_login_name                 = "lands-app"
#   app_source_db_name                = "lands"
#   app_rds_url                       = local.rds_url
#   app_rds_user                      = local.rds_user
#   app_rds_port                      = local.rds_port
#   app_rds_password                  = local.rds_password
#   app_source_db_url                 = local.source_db_url
#   app_source_db_user                = local.source_db_user
#   app_source_db_password            = local.source_db_password
#   environment                       = local.environment
#   application_data                  = local.application_data.accounts[local.environment]
#   tags                              = local.tags
#   dms_instance_arn                  = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
#   task_definition_volume            = local.application_data.accounts[local.environment].task_definition_volume
#   appscaling_min_capacity           = local.application_data.accounts[local.environment].appscaling_min_capacity
#   appscaling_max_capacity           = local.application_data.accounts[local.environment].appscaling_max_capacity
#   ecs_scaling_cpu_threshold         = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
#   ecs_scaling_mem_threshold         = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
#   app_count                         = local.application_data.accounts[local.environment].app_count
#   server_port                       = local.application_data.accounts[local.environment].server_port_1
#   cluster_id                        = aws_ecs_cluster.tribunals_cluster.id
#   cluster_name                      = aws_ecs_cluster.tribunals_cluster.name
#   vpc_shared_id                     = data.aws_vpc.shared.id
#   subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
#   aws_acm_certificate_external      = aws_acm_certificate.external
#   documents_location                = "JudgmentFiles"
#   waf_arn                           = local.waf_arn
# }

# module "transport" {
#   is_ftp_app                        = false
#   source                            = "./modules/tribunal"
#   app_name                          = "transport"
#   app_url                           = "transportappeals"
#   sql_migration_path                = "../scripts/transport"
#   app_db_name                       = "transport"
#   app_db_login_name                 = "transport-app"
#   app_source_db_name                = "Transport"
#   app_rds_url                       = local.rds_url
#   app_rds_user                      = local.rds_user
#   app_rds_port                      = local.rds_port
#   app_rds_password                  = local.rds_password
#   app_source_db_url                 = local.source_db_url
#   app_source_db_user                = local.source_db_user
#   app_source_db_password            = local.source_db_password
#   environment                       = local.environment
#   application_data                  = local.application_data.accounts[local.environment]
#   tags                              = local.tags
#   dms_instance_arn                  = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
#   task_definition_volume            = local.application_data.accounts[local.environment].task_definition_volume
#   appscaling_min_capacity           = local.application_data.accounts[local.environment].appscaling_min_capacity
#   appscaling_max_capacity           = local.application_data.accounts[local.environment].appscaling_max_capacity
#   ecs_scaling_cpu_threshold         = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
#   ecs_scaling_mem_threshold         = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
#   app_count                         = local.application_data.accounts[local.environment].app_count
#   server_port                       = local.application_data.accounts[local.environment].server_port_1
#   cluster_id                        = aws_ecs_cluster.tribunals_cluster.id
#   cluster_name                      = aws_ecs_cluster.tribunals_cluster.name
#   vpc_shared_id                     = data.aws_vpc.shared.id
#   subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
#   aws_acm_certificate_external      = aws_acm_certificate.external
#   documents_location                = "JudgmentFiles"
#   waf_arn                           = local.waf_arn
# }

module "charity_tribunal_decisions" {
  is_ftp_app                        = true
  source                            = "./modules/tribunal_ftp"
  app_name                          = "ftp-charity-tribunals"
  app_url                           = "charitytribunal"
  environment                       = local.environment
  application_data                  = local.application_data.accounts[local.environment]
  tags                              = local.tags
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
  documents_location                = "documents"
  waf_arn                           = local.waf_arn
}

module "claims_management_decisions" {
  is_ftp_app                        = true
  source                            = "./modules/tribunal_ftp"
  app_name                          = "ftp-claims-management"
  app_url                           = "claimsmanagement"
  environment                       = local.environment
  application_data                  = local.application_data.accounts[local.environment]
  tags                              = local.tags
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
  documents_location                = "Documents"
  waf_arn                           = local.waf_arn
}

module "consumer_credit_appeals" {
  is_ftp_app                        = true
  source                            = "./modules/tribunal_ftp"
  app_name                          = "ftp-consumer-credit"
  app_url                           = "consumercreditappeals"
  environment                       = local.environment
  application_data                  = local.application_data.accounts[local.environment]
  tags                              = local.tags
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
  documents_location                = "Documents"
  waf_arn                           = local.waf_arn
}

module "estate_agent_appeals" {
  is_ftp_app                        = true
  source                            = "./modules/tribunal_ftp"
  app_name                          = "ftp-estate-agents"
  app_url                           = "estateagentappeals"
  environment                       = local.environment
  application_data                  = local.application_data.accounts[local.environment]
  tags                              = local.tags
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
  documents_location                = "Documents"
  waf_arn                           = local.waf_arn
}

module "primary_health_lists" {
  is_ftp_app                        = true
  source                            = "./modules/tribunal_ftp"
  app_name                          = "ftp-primary-health"
  app_url                           = "primaryhealthlists"
  environment                       = local.environment
  application_data                  = local.application_data.accounts[local.environment]
  tags                              = local.tags
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
  documents_location                = "Documents"
  waf_arn                           = local.waf_arn
}

module "siac" {
  is_ftp_app                        = true
  source                            = "./modules/tribunal_ftp"
  app_name                          = "ftp-siac"
  app_url                           = "siac"
  environment                       = local.environment
  application_data                  = local.application_data.accounts[local.environment]
  tags                              = local.tags
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
  documents_location                = "Documents"
  waf_arn                           = local.waf_arn
}

module "sscs_venue_pages" {
  is_ftp_app                        = true
  source                            = "./modules/tribunal_ftp"
  app_name                          = "ftp-sscs-venues"
  app_url                           = "sscsvenues"
  environment                       = local.environment
  application_data                  = local.application_data.accounts[local.environment]
  tags                              = local.tags
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
  documents_location                = "Documents"
  waf_arn                           = local.waf_arn
}

module "tax_chancery_decisions" {
  is_ftp_app                        = true
  source                            = "./modules/tribunal_ftp"
  app_name                          = "ftp-tax-chancery"
  app_url                           = "taxchancerydecisions"
  environment                       = local.environment
  application_data                  = local.application_data.accounts[local.environment]
  tags                              = local.tags
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
  documents_location                = "Documents"
  waf_arn                           = local.waf_arn
}

module "tax_tribunal_decisions" {
  is_ftp_app                        = true
  source                            = "./modules/tribunal_ftp"
  app_name                          = "ftp-tax-tribunal"
  app_url                           = "taxtribunaldecisions"
  environment                       = local.environment
  application_data                  = local.application_data.accounts[local.environment]
  tags                              = local.tags
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
  documents_location                = "Documents"
  waf_arn                           = local.waf_arn
}

module "ftp_admin_appeals" {
  is_ftp_app                        = true
  source                            = "./modules/tribunal_ftp"
  app_name                          = "ftp-admin-appeals"
  app_url                           = "adminappealsreports"
  environment                       = local.environment
  application_data                  = local.application_data.accounts[local.environment]
  tags                              = local.tags
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
  documents_location                = "Documents"
  waf_arn                           = local.waf_arn
}
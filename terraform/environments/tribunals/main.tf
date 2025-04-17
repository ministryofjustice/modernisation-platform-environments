locals {
  rds_password = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
}

module "appeals" {
  is_ftp_app = false
  source     = "./modules/tribunal"
  # The app_name needs to match the folder name in the volume
  app_name                     = "appeals"
  module_name                  = "appeals"
  app_db_name                  = "ossc"
  app_db_login_name            = "ossc-app"
  app_rds_url                  = aws_db_instance.rdsdb.address
  app_rds_password             = local.rds_password
  environment                  = local.environment
  tags                         = local.tags
  support_email                = local.application_data.accounts[local.environment].support_email
  support_team                 = local.application_data.accounts[local.environment].support_team
  curserver                    = local.application_data.accounts[local.environment].curserver
  task_definition_volume       = local.application_data.accounts[local.environment].task_definition_volume
  appscaling_min_capacity      = local.application_data.accounts[local.environment].appscaling_min_capacity
  appscaling_max_capacity      = local.application_data.accounts[local.environment].appscaling_max_capacity
  ecs_scaling_cpu_threshold    = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
  ecs_scaling_mem_threshold    = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
  app_count                    = local.application_data.accounts[local.environment].app_count
  server_port                  = local.application_data.accounts[local.environment].server_port_1
  cluster_id                   = aws_ecs_cluster.tribunals_cluster.id
  cluster_name                 = aws_ecs_cluster.tribunals_cluster.name
  subnets_shared_public_ids    = data.aws_subnets.shared-public.ids
  documents_location           = "JudgmentFiles"
  target_group_attachment_port = var.services["appeals"].port
  target_group_arns            = local.target_group_arns
  target_group_arns_sftp       = local.target_group_arns_sftp
  new_db_password              = random_password.app_new_password.result
}

module "ahmlr" {
  is_ftp_app                   = false
  source                       = "./modules/tribunal"
  app_name                     = "hmlands"
  module_name                  = "ahmlr"
  app_db_name                  = "hmlands"
  app_db_login_name            = "hmlands-app"
  app_rds_url                  = aws_db_instance.rdsdb.address
  app_rds_password             = local.rds_password
  environment                  = local.environment
  tags                         = local.tags
  support_email                = local.application_data.accounts[local.environment].support_email
  support_team                 = local.application_data.accounts[local.environment].support_team
  curserver                    = local.application_data.accounts[local.environment].curserver
  task_definition_volume       = local.application_data.accounts[local.environment].task_definition_volume
  appscaling_min_capacity      = local.application_data.accounts[local.environment].appscaling_min_capacity
  appscaling_max_capacity      = local.application_data.accounts[local.environment].appscaling_max_capacity
  ecs_scaling_cpu_threshold    = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
  ecs_scaling_mem_threshold    = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
  app_count                    = local.application_data.accounts[local.environment].app_count
  server_port                  = local.application_data.accounts[local.environment].server_port_1
  cluster_id                   = aws_ecs_cluster.tribunals_cluster.id
  cluster_name                 = aws_ecs_cluster.tribunals_cluster.name
  subnets_shared_public_ids    = data.aws_subnets.shared-public.ids
  documents_location           = "Judgments"
  target_group_attachment_port = var.services["ahmlr"].port
  target_group_arns            = local.target_group_arns
  target_group_arns_sftp       = local.target_group_arns_sftp
  new_db_password              = random_password.app_new_password.result
}

module "care_standards" {
  is_ftp_app                   = false
  source                       = "./modules/tribunal"
  app_name                     = "care-standards"
  module_name                  = "care_standards"
  app_db_name                  = "carestandards"
  app_db_login_name            = "carestandards-app"
  app_rds_url                  = aws_db_instance.rdsdb.address
  app_rds_password             = local.rds_password
  environment                  = local.environment
  tags                         = local.tags
  support_email                = local.application_data.accounts[local.environment].support_email
  support_team                 = local.application_data.accounts[local.environment].support_team
  curserver                    = local.application_data.accounts[local.environment].curserver
  task_definition_volume       = local.application_data.accounts[local.environment].task_definition_volume
  appscaling_min_capacity      = local.application_data.accounts[local.environment].appscaling_min_capacity
  appscaling_max_capacity      = local.application_data.accounts[local.environment].appscaling_max_capacity
  ecs_scaling_cpu_threshold    = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
  ecs_scaling_mem_threshold    = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
  app_count                    = local.application_data.accounts[local.environment].app_count
  server_port                  = local.application_data.accounts[local.environment].server_port_1
  cluster_id                   = aws_ecs_cluster.tribunals_cluster.id
  cluster_name                 = aws_ecs_cluster.tribunals_cluster.name
  subnets_shared_public_ids    = data.aws_subnets.shared-public.ids
  documents_location           = "Judgments"
  target_group_attachment_port = var.services["care_standards"].port
  target_group_arns            = local.target_group_arns
  target_group_arns_sftp       = local.target_group_arns_sftp
  new_db_password              = random_password.app_new_password.result
}

module "cicap" {
  is_ftp_app                   = false
  source                       = "./modules/tribunal"
  app_name                     = "cicap"
  module_name                  = "cicap"
  app_db_name                  = "cicap"
  app_db_login_name            = "cicap-app"
  app_rds_url                  = aws_db_instance.rdsdb.address
  app_rds_password             = local.rds_password
  environment                  = local.environment
  tags                         = local.tags
  support_email                = local.application_data.accounts[local.environment].support_email
  support_team                 = local.application_data.accounts[local.environment].support_team
  curserver                    = local.application_data.accounts[local.environment].curserver
  task_definition_volume       = local.application_data.accounts[local.environment].task_definition_volume
  appscaling_min_capacity      = local.application_data.accounts[local.environment].appscaling_min_capacity
  appscaling_max_capacity      = local.application_data.accounts[local.environment].appscaling_max_capacity
  ecs_scaling_cpu_threshold    = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
  ecs_scaling_mem_threshold    = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
  app_count                    = local.application_data.accounts[local.environment].app_count
  server_port                  = local.application_data.accounts[local.environment].server_port_1
  cluster_id                   = aws_ecs_cluster.tribunals_cluster.id
  cluster_name                 = aws_ecs_cluster.tribunals_cluster.name
  subnets_shared_public_ids    = data.aws_subnets.shared-public.ids
  documents_location           = "CaseFiles"
  target_group_attachment_port = var.services["cicap"].port
  target_group_arns            = local.target_group_arns
  target_group_arns_sftp       = local.target_group_arns_sftp
  new_db_password              = random_password.app_new_password.result
}

module "employment_appeals" {
  is_ftp_app        = false
  source            = "./modules/tribunal"
  app_name          = "employment-appeals"
  module_name       = "employment_appeals"
  app_db_name       = "eat"
  app_db_login_name = "eat-app"
  app_rds_url       = aws_db_instance.rdsdb.address
  app_rds_password  = local.rds_password

  environment                  = local.environment
  tags                         = local.tags
  support_email                = local.application_data.accounts[local.environment].support_email
  support_team                 = local.application_data.accounts[local.environment].support_team
  curserver                    = local.application_data.accounts[local.environment].curserver
  task_definition_volume       = local.application_data.accounts[local.environment].task_definition_volume
  appscaling_min_capacity      = local.application_data.accounts[local.environment].appscaling_min_capacity
  appscaling_max_capacity      = local.application_data.accounts[local.environment].appscaling_max_capacity
  ecs_scaling_cpu_threshold    = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
  ecs_scaling_mem_threshold    = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
  app_count                    = local.application_data.accounts[local.environment].app_count
  server_port                  = local.application_data.accounts[local.environment].server_port_1
  cluster_id                   = aws_ecs_cluster.tribunals_cluster.id
  cluster_name                 = aws_ecs_cluster.tribunals_cluster.name
  subnets_shared_public_ids    = data.aws_subnets.shared-public.ids
  documents_location           = "Public/Upload"
  target_group_attachment_port = var.services["employment_appeals"].port
  target_group_arns            = local.target_group_arns
  target_group_arns_sftp       = local.target_group_arns_sftp
  new_db_password              = random_password.app_new_password.result
}

module "finance_and_tax" {
  is_ftp_app        = false
  source            = "./modules/tribunal"
  app_name          = "finance-and-tax"
  module_name       = "finance_and_tax"
  app_db_name       = "ftt"
  app_db_login_name = "ftt-app"
  app_rds_url       = aws_db_instance.rdsdb.address
  app_rds_password  = local.rds_password

  environment                  = local.environment
  tags                         = local.tags
  support_email                = local.application_data.accounts[local.environment].support_email
  support_team                 = local.application_data.accounts[local.environment].support_team
  curserver                    = local.application_data.accounts[local.environment].curserver
  task_definition_volume       = local.application_data.accounts[local.environment].task_definition_volume
  appscaling_min_capacity      = local.application_data.accounts[local.environment].appscaling_min_capacity
  appscaling_max_capacity      = local.application_data.accounts[local.environment].appscaling_max_capacity
  ecs_scaling_cpu_threshold    = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
  ecs_scaling_mem_threshold    = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
  app_count                    = local.application_data.accounts[local.environment].app_count
  server_port                  = local.application_data.accounts[local.environment].server_port_1
  cluster_id                   = aws_ecs_cluster.tribunals_cluster.id
  cluster_name                 = aws_ecs_cluster.tribunals_cluster.name
  subnets_shared_public_ids    = data.aws_subnets.shared-public.ids
  documents_location           = "JudgmentFiles"
  target_group_attachment_port = var.services["finance_and_tax"].port
  target_group_arns            = local.target_group_arns
  target_group_arns_sftp       = local.target_group_arns_sftp
  new_db_password              = random_password.app_new_password.result
}

module "immigration_services" {
  is_ftp_app        = false
  source            = "./modules/tribunal"
  app_name          = "immigration-services"
  module_name       = "immigration_services"
  app_db_name       = "imset"
  app_db_login_name = "imset-app"
  app_rds_url       = aws_db_instance.rdsdb.address
  app_rds_password  = local.rds_password

  environment                  = local.environment
  tags                         = local.tags
  support_email                = local.application_data.accounts[local.environment].support_email
  support_team                 = local.application_data.accounts[local.environment].support_team
  curserver                    = local.application_data.accounts[local.environment].curserver
  task_definition_volume       = local.application_data.accounts[local.environment].task_definition_volume
  appscaling_min_capacity      = local.application_data.accounts[local.environment].appscaling_min_capacity
  appscaling_max_capacity      = local.application_data.accounts[local.environment].appscaling_max_capacity
  ecs_scaling_cpu_threshold    = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
  ecs_scaling_mem_threshold    = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
  app_count                    = local.application_data.accounts[local.environment].app_count
  server_port                  = local.application_data.accounts[local.environment].server_port_1
  cluster_id                   = aws_ecs_cluster.tribunals_cluster.id
  cluster_name                 = aws_ecs_cluster.tribunals_cluster.name
  subnets_shared_public_ids    = data.aws_subnets.shared-public.ids
  documents_location           = "JudgmentFiles"
  target_group_attachment_port = var.services["immigration_services"].port
  target_group_arns            = local.target_group_arns
  target_group_arns_sftp       = local.target_group_arns_sftp
  new_db_password              = random_password.app_new_password.result
}

module "information_tribunal" {
  is_ftp_app        = false
  source            = "./modules/tribunal"
  app_name          = "information-tribunal"
  module_name       = "information_tribunal"
  app_db_name       = "it"
  app_db_login_name = "it-app"
  app_rds_url       = aws_db_instance.rdsdb.address
  app_rds_password  = local.rds_password

  environment                  = local.environment
  tags                         = local.tags
  support_email                = local.application_data.accounts[local.environment].support_email
  support_team                 = local.application_data.accounts[local.environment].support_team
  curserver                    = local.application_data.accounts[local.environment].curserver
  task_definition_volume       = local.application_data.accounts[local.environment].task_definition_volume
  appscaling_min_capacity      = local.application_data.accounts[local.environment].appscaling_min_capacity
  appscaling_max_capacity      = local.application_data.accounts[local.environment].appscaling_max_capacity
  ecs_scaling_cpu_threshold    = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
  ecs_scaling_mem_threshold    = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
  app_count                    = local.application_data.accounts[local.environment].app_count
  server_port                  = local.application_data.accounts[local.environment].server_port_1
  cluster_id                   = aws_ecs_cluster.tribunals_cluster.id
  cluster_name                 = aws_ecs_cluster.tribunals_cluster.name
  subnets_shared_public_ids    = data.aws_subnets.shared-public.ids
  documents_location           = "DBFiles"
  target_group_attachment_port = var.services["information_tribunal"].port
  target_group_arns            = local.target_group_arns
  target_group_arns_sftp       = local.target_group_arns_sftp
  new_db_password              = random_password.app_new_password.result
}

module "lands_tribunal" {
  is_ftp_app        = false
  source            = "./modules/tribunal"
  app_name          = "lands-chamber"
  module_name       = "lands_tribunal"
  app_db_name       = "lands"
  app_db_login_name = "lands-app"
  app_rds_url       = aws_db_instance.rdsdb.address
  app_rds_password  = local.rds_password

  environment                  = local.environment
  tags                         = local.tags
  support_email                = local.application_data.accounts[local.environment].support_email
  support_team                 = local.application_data.accounts[local.environment].support_team
  curserver                    = local.application_data.accounts[local.environment].curserver
  task_definition_volume       = local.application_data.accounts[local.environment].task_definition_volume
  appscaling_min_capacity      = local.application_data.accounts[local.environment].appscaling_min_capacity
  appscaling_max_capacity      = local.application_data.accounts[local.environment].appscaling_max_capacity
  ecs_scaling_cpu_threshold    = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
  ecs_scaling_mem_threshold    = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
  app_count                    = local.application_data.accounts[local.environment].app_count
  server_port                  = local.application_data.accounts[local.environment].server_port_1
  cluster_id                   = aws_ecs_cluster.tribunals_cluster.id
  cluster_name                 = aws_ecs_cluster.tribunals_cluster.name
  subnets_shared_public_ids    = data.aws_subnets.shared-public.ids
  documents_location           = "JudgmentFiles"
  target_group_attachment_port = var.services["lands_tribunal"].port
  target_group_arns            = local.target_group_arns
  target_group_arns_sftp       = local.target_group_arns_sftp
  new_db_password              = random_password.app_new_password.result
}

module "transport" {
  is_ftp_app        = false
  source            = "./modules/tribunal"
  app_name          = "transport"
  module_name       = "transport"
  app_db_name       = "transport"
  app_db_login_name = "transport-app"
  app_rds_url       = aws_db_instance.rdsdb.address
  app_rds_password  = local.rds_password

  environment                  = local.environment
  tags                         = local.tags
  support_email                = local.application_data.accounts[local.environment].support_email
  support_team                 = local.application_data.accounts[local.environment].support_team
  curserver                    = local.application_data.accounts[local.environment].curserver
  task_definition_volume       = local.application_data.accounts[local.environment].task_definition_volume
  appscaling_min_capacity      = local.application_data.accounts[local.environment].appscaling_min_capacity
  appscaling_max_capacity      = local.application_data.accounts[local.environment].appscaling_max_capacity
  ecs_scaling_cpu_threshold    = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
  ecs_scaling_mem_threshold    = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
  app_count                    = local.application_data.accounts[local.environment].app_count
  server_port                  = local.application_data.accounts[local.environment].server_port_1
  cluster_id                   = aws_ecs_cluster.tribunals_cluster.id
  cluster_name                 = aws_ecs_cluster.tribunals_cluster.name
  subnets_shared_public_ids    = data.aws_subnets.shared-public.ids
  documents_location           = "JudgmentFiles"
  target_group_attachment_port = var.services["transport"].port
  target_group_arns            = local.target_group_arns
  target_group_arns_sftp       = local.target_group_arns_sftp
  new_db_password              = random_password.app_new_password.result
}

module "asylum_support" {
  is_ftp_app        = false
  source            = "./modules/tribunal"
  app_name          = "asylum-support"
  module_name       = "asylum_support"
  app_db_name       = "asadj"
  app_db_login_name = "asadj-app"
  app_rds_url       = aws_db_instance.rdsdb.address
  app_rds_password  = local.rds_password

  environment                  = local.environment
  tags                         = local.tags
  support_email                = local.application_data.accounts[local.environment].support_email
  support_team                 = local.application_data.accounts[local.environment].support_team
  curserver                    = local.application_data.accounts[local.environment].curserver
  task_definition_volume       = local.application_data.accounts[local.environment].task_definition_volume
  appscaling_min_capacity      = local.application_data.accounts[local.environment].appscaling_min_capacity
  appscaling_max_capacity      = local.application_data.accounts[local.environment].appscaling_max_capacity
  ecs_scaling_cpu_threshold    = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
  ecs_scaling_mem_threshold    = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
  app_count                    = local.application_data.accounts[local.environment].app_count
  server_port                  = local.application_data.accounts[local.environment].server_port_1
  cluster_id                   = aws_ecs_cluster.tribunals_cluster.id
  cluster_name                 = aws_ecs_cluster.tribunals_cluster.name
  subnets_shared_public_ids    = data.aws_subnets.shared-public.ids
  documents_location           = "Judgments"
  target_group_attachment_port = var.services["asylum_support"].port
  target_group_arns            = local.target_group_arns
  target_group_arns_sftp       = local.target_group_arns_sftp
  new_db_password              = random_password.app_new_password.result
}

module "charity_tribunal_decisions" {
  is_ftp_app                        = true
  source                            = "./modules/tribunal_ftp"
  app_name                          = "ftp-charity-tribunals"
  module_name                       = "charity_tribunal_decisions"
  environment                       = local.environment
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
  subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
  target_group_attachment_port      = var.services["charity_tribunal_decisions"].port
  target_group_attachment_port_sftp = var.sftp_services["charity_tribunal_decisions"].sftp_port
  target_group_arns                 = local.target_group_arns
  target_group_arns_sftp            = local.target_group_arns_sftp
}

module "claims_management_decisions" {
  is_ftp_app                        = true
  source                            = "./modules/tribunal_ftp"
  app_name                          = "ftp-claims-management"
  module_name                       = "claims_management_decisions"
  environment                       = local.environment
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
  subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
  target_group_attachment_port      = var.services["claims_management_decisions"].port
  target_group_attachment_port_sftp = var.sftp_services["claims_management_decisions"].sftp_port
  target_group_arns                 = local.target_group_arns
  target_group_arns_sftp            = local.target_group_arns_sftp
}

module "consumer_credit_appeals" {
  is_ftp_app                        = true
  source                            = "./modules/tribunal_ftp"
  app_name                          = "ftp-consumer-credit"
  module_name                       = "consumer_credit_appeals"
  environment                       = local.environment
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
  subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
  target_group_attachment_port      = var.services["consumer_credit_appeals"].port
  target_group_attachment_port_sftp = var.sftp_services["consumer_credit_appeals"].sftp_port
  target_group_arns                 = local.target_group_arns
  target_group_arns_sftp            = local.target_group_arns_sftp
}

module "estate_agent_appeals" {
  is_ftp_app                        = true
  source                            = "./modules/tribunal_ftp"
  app_name                          = "ftp-estate-agents"
  module_name                       = "estate_agent_appeals"
  environment                       = local.environment
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
  subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
  target_group_attachment_port      = var.services["estate_agent_appeals"].port
  target_group_attachment_port_sftp = var.sftp_services["estate_agent_appeals"].sftp_port
  target_group_arns                 = local.target_group_arns
  target_group_arns_sftp            = local.target_group_arns_sftp
}

module "primary_health_lists" {
  is_ftp_app                        = true
  source                            = "./modules/tribunal_ftp"
  app_name                          = "ftp-primary-health"
  module_name                       = "primary_health_lists"
  environment                       = local.environment
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
  subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
  target_group_attachment_port      = var.services["primary_health_lists"].port
  target_group_attachment_port_sftp = var.sftp_services["primary_health_lists"].sftp_port
  target_group_arns                 = local.target_group_arns
  target_group_arns_sftp            = local.target_group_arns_sftp
}

module "siac" {
  is_ftp_app                        = true
  source                            = "./modules/tribunal_ftp"
  app_name                          = "ftp-siac"
  module_name                       = "siac"
  environment                       = local.environment
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
  subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
  target_group_attachment_port      = var.services["siac"].port
  target_group_attachment_port_sftp = var.sftp_services["siac"].sftp_port
  target_group_arns                 = local.target_group_arns
  target_group_arns_sftp            = local.target_group_arns_sftp
}

module "sscs_venue_pages" {
  is_ftp_app                        = true
  source                            = "./modules/tribunal_ftp"
  app_name                          = "ftp-sscs-venues"
  module_name                       = "sscs_venue_pages"
  environment                       = local.environment
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
  subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
  target_group_attachment_port      = var.services["sscs_venue_pages"].port
  target_group_attachment_port_sftp = var.sftp_services["sscs_venue_pages"].sftp_port
  target_group_arns                 = local.target_group_arns
  target_group_arns_sftp            = local.target_group_arns_sftp
}

module "tax_chancery_decisions" {
  is_ftp_app                        = true
  source                            = "./modules/tribunal_ftp"
  app_name                          = "ftp-tax-chancery"
  module_name                       = "tax_chancery_decisions"
  environment                       = local.environment
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
  subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
  target_group_attachment_port      = var.services["tax_chancery_decisions"].port
  target_group_attachment_port_sftp = var.sftp_services["tax_chancery_decisions"].sftp_port
  target_group_arns                 = local.target_group_arns
  target_group_arns_sftp            = local.target_group_arns_sftp
}

module "tax_tribunal_decisions" {
  is_ftp_app                        = true
  source                            = "./modules/tribunal_ftp"
  app_name                          = "ftp-tax-tribunal"
  module_name                       = "tax_tribunal_decisions"
  environment                       = local.environment
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
  subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
  target_group_attachment_port      = var.services["tax_tribunal_decisions"].port
  target_group_attachment_port_sftp = var.sftp_services["tax_tribunal_decisions"].sftp_port
  target_group_arns                 = local.target_group_arns
  target_group_arns_sftp            = local.target_group_arns_sftp
}

module "ftp_admin_appeals" {
  is_ftp_app                        = true
  source                            = "./modules/tribunal_ftp"
  app_name                          = "ftp-admin-appeals"
  module_name                       = "ftp_admin_appeals"
  environment                       = local.environment
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
  subnets_shared_public_ids         = data.aws_subnets.shared-public.ids
  target_group_attachment_port      = var.services["ftp_admin_appeals"].port
  target_group_attachment_port_sftp = var.sftp_services["ftp_admin_appeals"].sftp_port
  target_group_arns                 = local.target_group_arns
  target_group_arns_sftp            = local.target_group_arns_sftp
}

resource "aws_security_group" "nginx_lb_sg" {
  #checkov:skip=CKV_AWS_260:"Public HTTP access required for nginx load balancer"
  #checkov:skip=CKV_AWS_382:"Full egress access required for nginx operation"
  count       = local.is-development ? 1 : 0
  name        = "nginx-lb-sg"
  description = "Allow all web access to nginx load balancer"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all web access to nginx load balancer on port 80"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all web access to nginx load balancer on port 443"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

module "nginx" {
  count                 = local.is-development ? 1 : 0
  source                = "./modules/nginx_ec2_pair"
  nginx_lb_sg_id        = aws_security_group.nginx_lb_sg[0].id
  vpc_shared_id         = data.aws_vpc.shared.id
  public_subnets_a_id   = data.aws_subnet.public_subnets_a.id
  public_subnets_b_id   = data.aws_subnet.public_subnets_b.id
  environment           = local.environment
  s3_encryption_key_arn = aws_kms_key.s3_encryption_key.arn
}

module "nginx_load_balancer" {
  count                     = local.is-development ? 1 : 0
  source                    = "./modules/nginx_load_balancer"
  nginx_lb_sg_id            = aws_security_group.nginx_lb_sg[0].id
  nginx_instance_ids        = module.nginx[0].instance_ids
  subnets_shared_public_ids = data.aws_subnets.shared-public.ids
  vpc_shared_id             = data.aws_vpc.shared.id
  external_acm_cert_arn     = aws_acm_certificate.external.arn
}
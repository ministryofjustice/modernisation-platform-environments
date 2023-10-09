locals {
  rds_url               = "${aws_db_instance.rdsdb.address}"      
  rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
  rds_port              = "1433"
  rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
  source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
  source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
  source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]  
}

module "tribunal_template" {
  source                = "./modules/tribunal"
  app_name      = "tribunal_template"
  app_url       = "tribunal_template"
  sql_migration_path = ""
  app_db_name   = "tribunal_template"
  app_db_login_name = ""
  app_source_db_name = ""
  app_rds_url = local.rds_url
  app_rds_user = local.rds_user
  app_rds_port = local.rds_port
  app_rds_password = local.rds_password
  app_source_db_url = local.source_db_url
  app_source_db_user = local.source_db_user
  app_source_db_password = local.source_db_password
  environment = local.environment
  validation_record_fqdns = [local.cicap_domain_name_main[0], local.cicap_domain_name_sub[0]]
  application_data = local.application_data.accounts[local.environment]
  subnet_set_name = local.subnet_set_name
  vpc_all = local.vpc_all
  tags = local.tags
  dms_instance_arn = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
  networking_usiness_unit = var.networking[0].business-unit
  vpc_id = data.aws_vpc.shared.id
  shared_public_ids           = data.aws_subnets.shared-public.ids  
}

# module "administrative_appeals" {
#   source                = "./modules/administrative_appeals"
#   application_name      = "ossc"
#   environment           = local.environment
#   #db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
#   rds_url               = "${aws_db_instance.rdsdb.address}"      
#   rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
#   rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
#   source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
#   source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
#   source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
#   replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
# }

# module "ahmlr" {
#   source                = "./modules/ahmlr"
#   application_name      = "hmlands"
#   environment           = local.environment
#   #db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
#   rds_url               = "${aws_db_instance.rdsdb.address}"      
#   rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
#   rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
#   source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
#   source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
#   source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
#   replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
# }

# module "care_standards" {
#   source                = "./modules/care_standards"
#   application_name      = "carestandards"
#   environment           = local.environment
#   #db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
#   rds_url               = "${aws_db_instance.rdsdb.address}"      
#   rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
#   rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
#   source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
#   source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
#   source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
#   replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
# }

# module "cicap" {
#   source                = "./tribunals/cicap"
#   application_name      = "cicap"
#   environment           = local.environment
#   #db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
#   rds_url               = "${aws_db_instance.rdsdb.address}"      
#   rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
#   rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
#   source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
#   source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
#   source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
#   replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
# }

# module "employment_appeals" {
#   source                = "./modules/employment_appeals"
#   application_name      = "eat"
#   environment           = local.environment
#   #db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
#   rds_url               = "${aws_db_instance.rdsdb.address}"      
#   rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
#   rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
#   source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
#   source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
#   source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
#   replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
# }

# module "finance_and_tax" {
#   source                = "./modules/finance_and_tax"
#   application_name      = "ftt"
#   environment           = local.environment
#   #db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
#   rds_url               = "${aws_db_instance.rdsdb.address}"      
#   rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
#   rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
#   source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
#   source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
#   source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
#   replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
# }

# module "immigartion_services" {
#   source                = "./modules/immigartion_services"
#   application_name      = "imset"
#   environment           = local.environment
#   #db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
#   rds_url               = "${aws_db_instance.rdsdb.address}"      
#   rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
#   rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
#   source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
#   source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
#   source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
#   replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
# }

# module "information_tribunal" {
#   source                = "./modules/information_tribunal"
#   application_name      = "it"
#   environment           = local.environment
#   #db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
#   rds_url               = "${aws_db_instance.rdsdb.address}"      
#   rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
#   rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
#   source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
#   source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
#   source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
#   replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
# }

# # module "lands_chamber" {
# #   source                = "./modules/lands_chamber"
# #   application_name      = "lands"
# #   environment           = local.environment
# #   #db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
# #   rds_url               = "${aws_db_instance.rdsdb.address}"      
# #   rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
# #   rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
# #   source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
# #   source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
# #   source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
# #   replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
# # }

# # module "transport" {
# #   source                = "./modules/transport"
# #   application_name      = "transport"
# #   environment           = local.environment
# #   #db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
# #   rds_url               = "${aws_db_instance.rdsdb.address}"      
# #   rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
# #   rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
# #   source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
# #   source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
# #   source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
# #   replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
# #   curserver                   = local.application_data.accounts[local.environment].curserver
# #   support_team                = local.application_data.accounts[local.environment].support_team
# #   support_email               = local.application_data.accounts[local.environment].support_email
# #   moj_ip                      = local.application_data.accounts[local.environment].moj_ip
# #   vpc_id                      = data.aws_vpc.shared.id
# #   client_id                   = ""
# #   local_tags                  = local.tags
# #   shared_public_ids           = data.aws_subnets.shared-public.ids
# #   networking_business_unit    = var.networking[0].business-unit
# #   tribunal_locals             = locals

# #    providers = {
# #     core-network-services = aws.core-network-services
# #     core-vpc = aws.core-vpc
# #   }
# # }

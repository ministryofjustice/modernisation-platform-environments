module "administrative_appeals" {
  source                = "./modules/administrative_appeals"
  application_name      = "ossc"
  environment           = local.environment
  #db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
  rds_url               = "${aws_db_instance.rdsdb.address}"      
  rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
  rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
  source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
  source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
  source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
  replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
}

module "ahmlr" {
  source                = "./modules/ahmlr"
  application_name      = "hmlands"
  environment           = local.environment
  #db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
  rds_url               = "${aws_db_instance.rdsdb.address}"      
  rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
  rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
  source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
  source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
  source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
  replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
}

module "care_standards" {
  source                = "./modules/care_standards"
  application_name      = "carestandards"
  environment           = local.environment
  #db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
  rds_url               = "${aws_db_instance.rdsdb.address}"      
  rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
  rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
  source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
  source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
  source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
  replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
}

module "cicap" {
  source                = "./modules/cicap"
  application_name      = "cicap"
  environment           = local.environment
  #db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
  rds_url               = "${aws_db_instance.rdsdb.address}"      
  rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
  rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
  source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
  source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
  source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
  replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
}

module "employment_appeals" {
  source                = "./modules/employment_appeals"
  application_name      = "eat"
  environment           = local.environment
  #db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
  rds_url               = "${aws_db_instance.rdsdb.address}"      
  rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
  rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
  source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
  source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
  source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
  replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
}

module "finance_and_tax" {
  source                = "./modules/finance_and_tax"
  application_name      = "ftt"
  environment           = local.environment
  #db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
  rds_url               = "${aws_db_instance.rdsdb.address}"      
  rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
  rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
  source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
  source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
  source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
  replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
}

module "immigartion_services" {
  source                = "./modules/immigartion_services"
  application_name      = "imset"
  environment           = local.environment
  #db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
  rds_url               = "${aws_db_instance.rdsdb.address}"      
  rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
  rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
  source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
  source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
  source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
  replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
}

module "information_tribunal" {
  source                = "./modules/information_tribunal"
  application_name      = "it"
  environment           = local.environment
  #db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
  rds_url               = "${aws_db_instance.rdsdb.address}"      
  rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
  rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
  source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
  source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
  source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
  replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
}

module "lands_chamber" {
  source                = "./modules/lands_chamber"
  application_name      = "lands"
  environment           = local.environment
  #db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
  rds_url               = "${aws_db_instance.rdsdb.address}"      
  rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
  rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
  source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
  source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
  source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
  replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
}

module "transport" {
  source                = "./modules/transport"
  application_name      = "transport"
  environment           = local.environment
  #db_instance_identifier = local.application_data.accounts[local.environment].db_identifier
  rds_url               = "${aws_db_instance.rdsdb.address}"      
  rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
  rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
  source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
  source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
  source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
  replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
  curserver                   = local.application_data.accounts[local.environment].curserver
  support_team                = local.application_data.accounts[local.environment].support_team
  support_email               = local.application_data.accounts[local.environment].support_email
  moj_ip                      = local.application_data.accounts[local.environment].moj_ip
  vpc_id                      = data.aws_vpc.shared.id
  client_id                   = ""
  local_tags                  = local.tags
  shared_public_ids           = data.aws_subnets.shared-public.ids
  networking_business_unit    = var.networking[0].business-unit
  tribunal_locals             = locals

   providers = {
    tribs-core-network-services = aws.core-network-services
    tribs-core-vpc = aws.core-vpc
  }
}

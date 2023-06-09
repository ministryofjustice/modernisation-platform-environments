module "lands_chamber" {
  source                = "./modules/lands_chamber"
  application_name      = "lands_chamber"
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
}

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
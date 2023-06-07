module "lands_chamber" {
  source                 = "./modules/lands_chamber"
  application_name       = "lands_chamber"
  environment            = local.environment
  db_instance_identifier = local.application_data.accounts[local.environment].db_identifier   
  rds_user               = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
  rds_password           = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
 
}
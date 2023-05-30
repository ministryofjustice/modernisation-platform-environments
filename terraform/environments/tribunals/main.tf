module "transport" {
  source                 = "./modules/transport"
  application_name       = "tribs-transport-${local.environment}"
  environment            = local.environment
  db_instance_identifier = local.application_data.accounts[local.environment].identifier
  rds_secret_arn          = "arn:aws:secretsmanager:eu-west-2:263310006819:secret:tribunals-db-dev-credentials-WIKA7c"
}
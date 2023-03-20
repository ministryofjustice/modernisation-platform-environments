module "dms" {
  source = "github.com/ministryofjustice/terraform-tribunals-dms?ref=master"

  db_instance              = "tribunals-db-dev"
  db_hostname              = jsondecode(data.aws_secretsmanager_secret_version.rds.secret_string)["host"]
  db_password              = jsondecode(data.aws_secretsmanager_secret_version.rds.secret_string)["password"]
  db_username              = jsondecode(data.aws_secretsmanager_secret_version.rds.secret_string)["username"]
  dms_source_db_password   = jsondecode(data.aws_secretsmanager_secret_version.source-db.secret_string)["password"]
  dms_source_db_username   = jsondecode(data.aws_secretsmanager_secret_version.source-db.secret_string)["username"]
  dms_source_db_hostname   = jsondecode(data.aws_secretsmanager_secret_version.source-db.secret_string)["host"]
  dms_replication_instance = module.dms.dms_replication_instance
  region                   = "eu-west-2"
  application_name         = "tribunals"
  source_db_name           = "default"
  target_db_name           = "default"
  environment              = "dev"
}
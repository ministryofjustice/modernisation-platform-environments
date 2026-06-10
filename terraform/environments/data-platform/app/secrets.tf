module "app_rds_credentials" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "${local.component_name}/rds"

  secret_string = jsonencode({
    username = module.app_rds.db_instance_username
    password = random_password.app_rds.result
    host     = module.app_rds.db_instance_address
    port     = tostring(module.app_rds.db_instance_port)
    dbname   = module.app_rds.db_instance_name
  })
}

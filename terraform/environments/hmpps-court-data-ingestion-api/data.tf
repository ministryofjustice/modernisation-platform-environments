#### This file can be used to store data specific to the member account ####

data "aws_secretsmanager_secret_version" "cloud_platform_account_id" {
  secret_id  = module.secret_cloud_platform_account_id.secret_id
  depends_on = [module.secret_cloud_platform_account_id]
}




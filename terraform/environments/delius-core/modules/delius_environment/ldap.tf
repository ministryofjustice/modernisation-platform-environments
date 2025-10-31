module "ldap" {

  source = "../components/ldap"

  providers = {
    aws                       = aws
    aws.bucket-replication    = aws.bucket-replication
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  env_name       = var.env_name
  account_config = var.account_config
  account_info   = var.account_info
  ldap_config    = var.ldap_config

  platform_vars           = var.platform_vars
  tags                    = local.tags
  enable_platform_backups = var.enable_platform_backups
  task_role_arn           = "arn:aws:iam::${var.account_info.id}:role/${var.env_name}-ldap-ecs-task"
}

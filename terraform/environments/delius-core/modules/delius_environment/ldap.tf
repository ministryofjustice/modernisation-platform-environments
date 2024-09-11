module "ldap" {

  source = "../components/ldap"

  providers = {
    aws                       = aws
    aws.bucket-replication    = aws.bucket-replication
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  env_name           = var.env_name
  account_config     = var.account_config
  account_info       = var.account_info
  environment_config = var.environment_config
  ldap_config        = var.ldap_config

  bastion_sg_id = module.bastion_linux.bastion_security_group

  sns_topic_arn   = aws_sns_topic.delius_core_alarms.arn
  ecs_cluster_arn = module.ecs.ecs_cluster_arn
  task_role_arn   = module.ldap_ecs.task_role_arn

  platform_vars           = var.platform_vars
  tags                    = local.tags
  enable_platform_backups = var.enable_platform_backups
}

module "dms" {
  source                     = "../components/dms"
  account_config             = var.account_config
  account_info               = var.account_info
  tags                       = var.tags
  env_name                   = var.env_name
  replication_instance_class = var.dms_config.replication_instance_class

  providers = {
    aws                    = aws
    aws.bucket-replication = aws
  }
}

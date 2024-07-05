module "dms" {
  source         = "./modules/components/dms"
  account_config = local.account_config
  account_info   = local.account_info
  tags           = local.tags
  env_name       = local.environment
  dms_config = lookup(local.dms_config, terraform.workspace, {
    replication_instance_class = "dms.t3.small"
    engine_version             = "3.5.1"
  })
  providers = {
    aws                    = aws
    aws.bucket-replication = aws
  }
}

locals {
  dms_config = {
    "delius-core-development" = {
      replication_instance_class = "dms.t3.small"
      engine_version             = "3.5.1"
    }
    "delius-core-test" = {
      replication_instance_class = "dms.t3.medium"
      engine_version             = "3.5.1"
    }
  }
}
module "efs" {
  source                          = "../efs"

  providers = {
    aws                           = aws
    aws.bucket-replication        = aws
    aws.core-vpc                  = aws.core-vpc
    aws.core-network-services     = aws.core-network-services
  }

  name                            = "ldap-efs-${var.env_name}"
  env_name                        = var.env_name
  creation_token                  = "${var.env_name}-ldap"
  account_config                  = var.account_config
  ldap_config                     = var.ldap_config
  account_info                    = var.account_info 

  kms_key_arn                     = var.account_config.general_shared_kms_key_arn
  throughput_mode                 = var.ldap_config.efs_throughput_mode
  provisioned_throughput_in_mibps = var.ldap_config.efs_provisioned_throughput  
  tags                            = local.tags
}

module "nlb" {
  source                      = "../nlb"

  providers = {
    aws                       = aws
    aws.bucket-replication    = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }
  
  env_name         = var.env_name 
  internal         = var.internal
  tags             = local.tags
  account_config   = var.account_config
  account_info     = var.account_info
}

module "ldap_backups" {

  source           = "../components/ldap"
  
  providers = {
    aws                       = aws
    aws.bucket-replication    = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  env_name         = var.env_name
  account_config   = var.account_config
  account_info     = var.account_info
  ldap_config      = var.ldap_config
  platform_vars    = var.platform_vars
  tags             = local.tags
}

module "ldap_datasync" {

  source           = "../components/ldap"
  providers = {
    aws                       = aws
    aws.bucket-replication    = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  env_name         = var.env_name 
  ldap_config      = var.ldap_config
  account_config   = var.account_config
  account_info     = var.account_info
  tags             = local.tags
  platform_vars = var.platform_vars
}

# module "ldap_params" {

#   source           = "../components/ldap/ldap_params"

#   env_name         = var.env_name 
#   internal         = var.internal 
#   tags             = local.tags
# }
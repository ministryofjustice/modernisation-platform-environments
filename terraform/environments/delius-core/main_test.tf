##
# Modules for each environment 
# Separate per environment to allow different versions
##
module "environment_test1" {
  # We're in dev account and dev environment, could reference different version
  source = "./modules/environment_all_components"

  providers = {
    aws.core-vpc               = aws.core-vpc
  }

  count  = local.environment == "test" ? 1 : 0

  name                        = "test1"
  ldap_config                 = local.ldap_config_test1
  db_config                   = local.db_config_test1
  db_config_instance          = local.db_config_test1.instance
  db_config_ebs_volume_config = local.db_config_test1.ebs_volume_config
  db_config_ebs_volumes       = local.db_config_test1.ebs_volumes
  db_config_route53_records   = local.db_config_test1.route53_records
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  db_config_tags              = local.db_config_test1.tags
  aws_kms_key_general_shared_arn = data.aws_kms_key.general_shared.arn

  account_info                = local.account_info
  tags                        = local.tags_all
}

module "environment_test2" {
  # We're in dev account and dev environment, could reference different version
  source = "./modules/environment_all_components"
  providers = {
    aws.core-vpc               = aws.core-vpc
  }

  count  = local.environment == "test" ? 1 : 0

  name                        = "test2"
  ldap_config                 = local.ldap_config_test2
  db_config                   = local.db_config_test2
  db_config_instance          = local.db_config_test2.instance
  db_config_ebs_volume_config = local.db_config_test2.ebs_volume_config
  db_config_ebs_volumes       = local.db_config_test2.ebs_volumes
  db_config_route53_records   = local.db_config_test2.route53_records
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  db_config_tags              = local.db_config_test2.tags
  aws_kms_key_general_shared_arn = data.aws_kms_key.general_shared.arn

  account_info                = local.account_info
  tags                        = local.tags_all
}

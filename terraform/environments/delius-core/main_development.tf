##
# Modules for each environment 
# Separate per environment to allow different versions
##
module "environment_dev" {
  # We're in dev account and dev environment, could reference different version
  source = "./modules/environment_all_components"
  count  = local.environment == "development" ? 1 : 0

  providers = {
    aws.bucket-replication    = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  env_name = "dev"
  app_name = local.application_name

  domain        = local.domain
  platform_vars = local.platform_vars

  network_config  = local.network_config_dev
  ldap_config     = local.ldap_config_dev
  db_config       = local.db_config_dev
  weblogic_config = local.weblogic_config_dev


  account_info = local.account_info

  tags = local.tags
}

#module "environment_dev2" {
#  # We're in dev account and dev environment, could reference different version
#  source = "./modules/environment_all_components"
#  count  = local.environment == "development" ? 1 : 0
#
#  providers = {
#    aws.bucket-replication = aws
#    aws.core-vpc           = aws.core-vpc
#  }
#
#  env_name = "dev2"
#  app_name = local.application_name
#   
#  network_config = local.network_config_dev2
#  ldap_config = local.ldap_config_dev2
#  db_config   = local.db_config_dev2
#
#  account_info = local.account_info
#
#  tags = local.tags
#}
resource "aws_acm_certificate" "external" {
  domain_name               = "modernisation-platform.service.justice.gov.uk"
  validation_method         = "DNS"
  subject_alternative_names = [local.frontend_url]
  tags                      = local.tags

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0]]
}


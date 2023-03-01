module "environment" {
  source = "../../modules/environment"

  providers = {
    aws.core-network-services = aws.core-network-services
    aws.core-vpc              = aws.core-vpc
  }

  environment_management = local.environment_management
  business_unit          = local.business_unit
  application_name       = local.application_name
  environment            = local.environment
  subnet_set             = local.subnet_set
}

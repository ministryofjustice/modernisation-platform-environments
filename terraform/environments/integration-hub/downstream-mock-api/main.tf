module "service" {
  count  = local.is-development ? 1 : 0
  source = "./modules/service"

  account_id                = data.aws_caller_identity.current.account_id
  environment               = local.environment
  kms_key_arn               = data.aws_kms_key.general_shared.arn
  private_subnet_ids        = data.aws_subnets.shared-private.ids
  region                    = data.aws_region.current.region
  resource_application_name = local.resource_application_name
  service_configuration     = local.service_configuration
  tags                      = local.tags
  vpc = {
    cidr_block = data.aws_vpc.shared.cidr_block
    id         = data.aws_vpc.shared.id
  }
}

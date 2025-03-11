module "cwa-poc2-environment" {
  source = "./cwa-poc2"

  providers = {
    aws.share-host            = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
    aws                       = aws          # The default provider (unaliased, `aws`) is the tenant
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  environment                      = local.environment
  application_data                 = local.application_data
  tags                             = local.tags
  route53_zone_external            = data.aws_route53_zone.external.name
  route53_zone_external_id         = data.aws_route53_zone.external.zone_id
  route53_zone_network_services_id = data.aws_route53_zone.network-services.zone_id
  shared_ebs_kms_key_id            = data.aws_kms_key.ebs_shared.key_id
  shared_vpc_id                    = data.aws_vpc.shared.id
  shared_vpc_cidr                  = data.aws_vpc.shared.cidr_block
  bastion_security_group           = module.bastion_linux.bastion_security_group
  current_account_id               = data.aws_caller_identity.current.account_id
  public_subnet_a_id               = data.aws_subnet.public_subnets_a.id
  public_subnet_b_id               = data.aws_subnet.public_subnets_b.id
  public_subnet_c_id               = data.aws_subnet.public_subnets_c.id
  data_subnet_a_id                 = data.aws_subnet.data_subnets_a.id
  private_subnet_a_id              = data.aws_subnet.private_subnets_a.id
  management_aws_account           = local.environment_management.account_ids[terraform.workspace]
}
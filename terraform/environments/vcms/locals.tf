#### This file can be used to store locals specific to the member account ####

locals {
  account_info = {
    business_unit    = var.networking[0].business-unit
    region           = "eu-west-2"
    vpc_id           = data.aws_vpc.shared.id
    application_name = local.application_name
    mp_environment   = local.environment
    id               = data.aws_caller_identity.current.account_id
  }
  account_config = {
    shared_vpc_cidr               = data.aws_vpc.shared.cidr_block
    private_subnet_ids            = data.aws_subnets.shared-private.ids
    public_subnet_ids             = data.aws_subnets.shared-public.ids
    #    ordered_private_subnet_ids    = local.ordered_subnet_ids
    #ordered_subnets               = [local.ordered_subnet_ids]
    data_subnet_ids               = data.aws_subnets.shared-data.ids
    data_subnet_a_id              = data.aws_subnet.data_subnets_a.id
    route53_inner_zone            = data.aws_route53_zone.inner
    route53_network_services_zone = data.aws_route53_zone.network-services
    route53_external_zone         = data.aws_route53_zone.external
    shared_vpc_id                 = data.aws_vpc.shared.id
    kms_keys = {
      ebs_shared     = data.aws_kms_key.ebs_shared.arn
      general_shared = data.aws_kms_key.general_shared.arn
      rds_shared     = data.aws_kms_key.rds_shared.arn
    }
    dns_suffix          = "${local.application_name}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
    internal_dns_suffix = "${local.application_name}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.internal"
  }
  bastion_config = {}
  image_tag = "latest"

}

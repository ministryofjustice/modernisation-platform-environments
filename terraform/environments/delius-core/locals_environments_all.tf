locals {
  account_info = {
    business_unit    = var.networking[0].business-unit
    region           = "eu-west-2"
    vpc_id           = data.aws_vpc.shared.id
    application_name = local.application_name
    mp_environment   = local.environment
    id               = data.aws_caller_identity.current.account_id
    cp_cidr          = "172.20.0.0/16"
  }

  account_config = {
    shared_vpc_cidr               = data.aws_vpc.shared.cidr_block
    private_subnet_ids            = data.aws_subnets.shared-private.ids
    public_subnet_ids             = data.aws_subnets.shared-public.ids
    ordered_private_subnet_ids    = local.ordered_subnet_ids
    ordered_subnets               = [local.ordered_subnet_ids]
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

  platform_vars = {
    environment_management = local.environment_management
  }

  pagerduty_integration_keys = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
  integration_key_lookup     = local.is-production ? "delius_core_prod_alarms" : "delius_core_nonprod_alarms"
  pagerduty_integration_key  = local.pagerduty_integration_keys[local.integration_key_lookup]

}

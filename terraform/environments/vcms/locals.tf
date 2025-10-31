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
    shared_vpc_cidr    = data.aws_vpc.shared.cidr_block
    private_subnet_ids = data.aws_subnets.shared-private.ids
    public_subnet_ids  = data.aws_subnets.shared-public.ids
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

  app_config = {
    container_port                     = 80
    container_cpu                      = "512"
    task_memory                        = "1024"
    desired_count                      = 1
    deployment_maximum_percent         = 100
    deployment_minimum_healthy_percent = 0
    health_check_grace_period_seconds  = 60
  }

  bastion_config = {}
  image_tag      = "initial-16447252449-1"
  image_uri      = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/vcms:${local.image_tag}"
  app_port       = 80
  internal_security_group_cidrs = distinct(flatten([
    module.ip_addresses.moj_cidrs.trusted_moj_digital_staff_public,
    module.ip_addresses.moj_cidrs.trusted_moj_enduser_internal,
    module.ip_addresses.moj_cidrs.trusted_mojo_public,
    module.ip_addresses.moj_cidr.ark_dc_external_internet,
    module.ip_addresses.moj_cidr.vodafone_dia_networks,
    module.ip_addresses.moj_cidr.palo_alto_prisma_access_corporate,
    module.ip_addresses.moj_cidr.mojo_azure_landing_zone_egress,
    [
      # Route53 Healthcheck Access Cidrs
      # London Region not support yet, so metrics are not yet publised, can be enabled at later stage for Route53 endpoint monitor
      "15.177.0.0/18",     # GLOBAL Region
      "54.251.31.128/26",  # ap-southeast-1 Region
      "54.255.254.192/26", # ap-southeast-1 Region
      "176.34.159.192/26", # eu-west-1 Region
      "54.228.16.0/26",    # eu-west-1 Region
      "107.23.255.0/26",   # us-east-1 Region
      "54.243.31.192/26"   # us-east-1 Region
    ]
  ]))
  ipv6_cidr_blocks = []

  domain_types = { for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }

  domain                  = local.is-production ? "vcms.probation.service.justice.gov.uk" : "modernisation-platform.service.justice.gov.uk"
  domain_name_main        = [for k, v in local.domain_types : v.name if k == local.domain]
  domain_record_main      = [for k, v in local.domain_types : v.record if k == local.domain]
  domain_type_main        = [for k, v in local.domain_types : v.type if k == local.domain]
  domain_name_sub         = [for k, v in local.domain_types : v.name if k == local.app_url]
  domain_record_sub       = [for k, v in local.domain_types : v.record if k == local.app_url]
  domain_type_sub         = [for k, v in local.domain_types : v.type if k == local.app_url]
  validation_record_fqdns = local.is-development ? [local.domain_name_main[0], local.domain_name_sub[0]] : [local.domain_name_main[0], local.domain_name_sub[0]]

  app_url                       = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.${local.domain}"
  acm_subject_alternative_names = [local.app_url]

}

module "ip_addresses" {
  source = "../../modules/ip_addresses"
}

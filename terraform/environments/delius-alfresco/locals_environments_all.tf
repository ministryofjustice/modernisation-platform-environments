locals {
  delius_environments_per_account = {
    # account = [env1, env2]
    prod     = ["prod"]
    pre_prod = ["stage", "preprod"]
    test     = ["test"]
    dev      = ["dev", "poc"]
  }

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

  # certificate_arn = data.aws_acm_certificate.mp_service

  ldap_error_codes = [
    1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 14,
    16, 17, 18, 19, 20, 21, 33, 34, 35, 36, 48, 49,
    50, 51, 52, 53, 54, 60, 61, 64, 65, 66, 67, 68,
    69, 70, 71, 76, 80, 81, 82, 83, 84, 85, 86, 87,
    88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 100, 101,
    112, 113, 114, 118, 119, 120, 121, 122, 123, 4096,
    16654
  ]
  ldap_formatted_error_codes = [for error_code in local.ldap_error_codes : "err=${error_code}\\s"]

  # Merge tags from the environment json file with additional ones
  tags_all = merge(
    jsondecode(data.http.environments_file.response_body).tags,
    { "is-production" = local.is-production },
    { "environment-name" = terraform.workspace },
    { "source-code" = "https://github.com/ministryofjustice/modernisation-platform-environments" }
  )
}

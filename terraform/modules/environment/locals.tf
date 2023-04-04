locals {
  vpc_name     = "${var.business_unit}-${var.environment}"    # e.g. hmpps-development
  account_name = "${var.application_name}-${var.environment}" # e.g. nomis-development

  possible_account_names = [
    "${var.application_name}-development",
    "${var.application_name}-test",
    "${var.application_name}-preproduction",
    "${var.application_name}-production",
  ]

  account_names = flatten([
    for name in local.possible_account_names : [
      contains(keys(var.environment_management.account_ids), name) ? [name] : []
    ]
  ])

  devtest_account_names = flatten([
    for name in local.account_names : [
      endswith(name, "-development") || endswith(name, "-test") ? [name] : []
    ]
  ])

  prodpreprod_account_names = flatten([
    for name in local.account_names : [
      endswith(name, "-production") || endswith(name, "-preproduction") ? [name] : []
    ]
  ])

  subnet_names = {
    general = ["data", "private", "public"]
  }

  domains = {
    public = {
      modernisation_platform    = "modernisation-platform.service.justice.gov.uk"
      business_unit_environment = "${var.business_unit}-${var.environment}.modernisation-platform.service.justice.gov.uk"
      application_environment   = "${var.application_name}.${var.business_unit}-${var.environment}.modernisation-platform.service.justice.gov.uk"
    }
    internal = {
      modernisation_platform    = "modernisation-platform.internal"
      business_unit_environment = "${var.business_unit}-${var.environment}.modernisation-platform.internal"
      application_environment   = "${var.application_name}.${var.business_unit}-${var.environment}.modernisation-platform.internal"
    }
  }

  route53_zones = {
    "${local.domains.public.modernisation_platform}" = {
      account      = "core-network-services"
      private_zone = false
    }
    "${local.domains.public.business_unit_environment}" = {
      account      = "core-vpc"
      private_zone = false
    }
    "${local.domains.internal.modernisation_platform}" = {
      account      = "core-network-services"
      private_zone = true
    }
    "${local.domains.internal.business_unit_environment}" = {
      account      = "core-vpc"
      private_zone = true
    }
  }

  cmk_name_prefixes = ["general", "ebs", "rds"]


  environments_file   = jsondecode(data.http.environments_file.response_body)
  environments_access = { for item in local.environments_file.environments : item.name => item.access }

  # environments_file provides application, business-unit, infrastructure-support and owner tags
  tags = merge(local.environments_file.tags, {
    is-production    = var.environment == "production" ? "true" : "false"
    environment-name = local.account_name
    source-code      = "https://github.com/ministryofjustice/modernisation-platform-environments"
  })

  subnet_name_availability_zone = [
    for subnet_name in local.subnet_names[var.subnet_set] : [
      for zone_name in data.aws_availability_zones.this.names : "${subnet_name}-${zone_name}"
    ]
  ]
}

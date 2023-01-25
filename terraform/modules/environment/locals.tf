locals {
  region                  = "eu-west-2"
  vpc_name                = "${var.business_unit}-${var.environment}"    # e.g. hmpps-development
  application_environment = "${var.application_name}-${var.environment}" # e.g. nomis-development

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
}

locals {

  environments_file   = jsondecode(data.http.environments_file.response_body)
  environments_access = { for item in local.environments_file.environments : item.name => item.access }

  # environments_file provides application, business-unit, infrastructure-support and owner tags
  tags = merge(local.environments_file.tags, {
    is-production    = var.environment == "production" ? "true" : "false"
    environment-name = local.application_environment
    source-code      = "https://github.com/ministryofjustice/modernisation-platform-environments"
  })
}

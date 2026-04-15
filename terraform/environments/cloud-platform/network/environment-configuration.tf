locals {
  environment_configurations = {
    development_cluster = {
      account_hosted_zone = "development-temp.cloud-platform.service.justice.gov.uk"
      route53_prefix      = terraform.workspace
    }

    development = {
      account_hosted_zone = "development-temp.cloud-platform.service.justice.gov.uk"
      route53_prefix      = "eks"
    }

    preproduction = {
      account_hosted_zone = "preproduction-temp.cloud-platform.service.justice.gov.uk"
      route53_prefix      = "eks"
    }

    nonlive = {
      account_hosted_zone = "nonlive-temp.cloud-platform.service.justice.gov.uk"
      route53_prefix      = "eks"
    }

    live = {
      account_hosted_zone = "live-temp.cloud-platform.service.justice.gov.uk"
      route53_prefix      = "eks"
    }
  }
}
locals {
  environment_configurations = {
    development_cluster = {

      /* Route53 */
      route53_zone = "development.temp.cloud-platform.service.justice.gov.uk"

    }

    development = {

      /* Route53 */
      route53_zone = "development.temp.cloud-platform.service.justice.gov.uk"

    }

    preproduction = {

      /* Route53 */
      route53_zone = "preproduction.temp.cloud-platform.service.justice.gov.uk"
      
    }

    nonlive = {

      /* Route53 */
      route53_zone = "nonlive.temp.cloud-platform.service.justice.gov.uk"

    }

    live = {

      /* Route53 */
      route53_zone = "live.temp.cloud-platform.service.justice.gov.uk"

    }
  }
}
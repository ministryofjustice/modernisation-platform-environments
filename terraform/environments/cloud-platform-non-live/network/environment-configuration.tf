locals {
  environment_configurations = {
    development_cluster = {

      /* Route53 */
      route53_zone = "non-live-development.temp.cloud-platform.service.justice.gov.uk"

    }

    development = {

      /* Route53 */
      route53_zone = "non-live-development.temp.cloud-platform.service.justice.gov.uk"

    }

    test = {

      /* Route53 */
      route53_zone = "non-live-test.temp.cloud-platform.service.justice.gov.uk"

    }

    preproduction = {

      /* Route53 */
      route53_zone = "non-live-preproduction.temp.cloud-platform.service.justice.gov.uk"
      
    }

    production = {

      /* Route53 */
      route53_zone = "non-live-production.temp.cloud-platform.service.justice.gov.uk"

    }
  }
}

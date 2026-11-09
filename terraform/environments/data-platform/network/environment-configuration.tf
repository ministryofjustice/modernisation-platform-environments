locals {
  environment_configurations = {
    development = {
      /* Route53 */
      route53_zone = "development.data-platform.service.justice.gov.uk"
    }
    test = {
      /* Route53 */
      route53_zone = "test.data-platform.service.justice.gov.uk"
    }
    preproduction = {
      /* Route53 */
      route53_zone = "preproduction.data-platform.service.justice.gov.uk"
    }
    production = {
      /* Route53 */
      route53_zone = "data-platform.service.justice.gov.uk"
    }
  }
}

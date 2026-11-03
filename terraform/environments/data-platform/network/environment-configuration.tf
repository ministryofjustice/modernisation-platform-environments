locals {
  environment_configurations = {
    development   = {}
    test          = {
      /* Route53 */
      route53_zone = "test.data-platform.service.justice.gov.uk"
    }
    preproduction = {}
    production    = {}
  }
}

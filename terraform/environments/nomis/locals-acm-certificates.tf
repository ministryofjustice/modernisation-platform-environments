locals {

  acm_certificates = {

    #--------------------------------------------------------------------------
    # define certificates common to all environments here
    #--------------------------------------------------------------------------
    common = {
      # e.g. star.nomis.hmpps-development.modernisation-platform.service.justice.gov.uk
      "star.${module.environment.domains.public.application_environment}" = {
        # domain_name limited to 64 chars so put it in the san instead
        domain_name             = module.environment.domains.public.modernisation_platform
        subject_alternate_names = ["*.${module.environment.domains.public.application_environment}"]
        validation = {
          "${module.environment.domains.public.modernisation_platform}" = {
            account   = "core-network-services"
            zone_name = "${module.environment.domains.public.modernisation_platform}."
          }
          "*.${module.environment.domains.public.application_environment}" = {
            account   = "core-vpc"
            zone_name = "${module.environment.domains.public.business_unit_environment}."
          }
        }
        tags = {
          description = "wildcard cert for ${module.environment.domains.public.application_environment} domain"
        }
      }
    }
    cloudwatch_metric_alarms_acm = {
      cert-expires-in-30-days = {
        comparison_operator = "LessThanThreshold"
        evaluation_periods  = "1"
        metric_name         = "DaysToExpiry"
        namespace           = "AWS/CertificateManager"
        period              = "86400"
        statistic           = "Average"
        threshold           = "30"
        alarm_description   = "This metric monitors the number of days until the certificate expires. If the number of days is less than 30."
        alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
      }
      cert-expires-in-2-days = {
        comparison_operator = "LessThanThreshold"
        evaluation_periods  = "1"
        metric_name         = "DaysToExpiry"
        namespace           = "AWS/CertificateManager"
        period              = "86400"
        statistic           = "Average"
        threshold           = "2"
        alarm_description   = "This metric monitors the number of days until the certificate expires. If the number of days is less than 2."
        alarm_actions       = [aws_sns_topic.nomis_nonprod_alarms.arn]
      }
    }

    #--------------------------------------------------------------------------
    # define environment specific certificates here
    #--------------------------------------------------------------------------

    development   = {}
    test          = {}
    preproduction = {}
    production    = {}
  }
}

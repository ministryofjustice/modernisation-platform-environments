locals {

  acm_certificates = {

    #--------------------------------------------------------------------------
    # define certificates common to all environments here
    #--------------------------------------------------------------------------
    common = {
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

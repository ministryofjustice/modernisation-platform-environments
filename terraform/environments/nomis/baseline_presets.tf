locals {
  baseline_presets_options = {
    enable_application_environment_wildcard_cert = false
    enable_business_unit_kms_cmks                = true
    enable_image_builder                         = true
    enable_ec2_cloud_watch_agent                 = true
    enable_ec2_self_provision                    = true
    cloudwatch_metric_alarms = {
      nomis_alarms = {
        alarm_actions = [aws_sns_topic.nomis_alarms.arn]
        application_alarms = {
          weblogic = local.ec2_weblogic.cloudwatch_metric_alarms
          database = local.database.cloudwatch_metric_alarms
        }
      }
      nomis_nonprod_alarms = {
        alarm_actions = [aws_sns_topic.nomis_nonprod_alarms.arn]
        application_alarms = {
          weblogic = local.ec2_weblogic.cloudwatch_metric_alarms
          database = local.database.cloudwatch_metric_alarms
        }
      }
    }
    route53_resolver_rules = {
      outbound-data-and-private-subnets = ["azure-fixngo-domain"]
    }
    s3_iam_policies = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    # sns_topics_pagerduty_integrations = {
    #   nomis_alarms         = "nomis_alarms"
    #   nomis_nonprod_alarms = "nomis_nonprod_alarms"
    # }
  }
}

module "baseline_presets" {
  source = "../../modules/baseline_presets"

  environment  = module.environment
  ip_addresses = module.ip_addresses
  options      = local.baseline_presets_options
}

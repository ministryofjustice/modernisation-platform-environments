locals {

  baseline_presets_options = {
    enable_application_environment_wildcard_cert = false
    enable_business_unit_kms_cmks                = true
    # enable_image_builder                         = true
    enable_ec2_cloud_watch_agent = true
    enable_ec2_self_provision    = true
    cloudwatch_metric_alarms = {
      acm = {
        cert-expiry-alarm-test = {
          comparison_operator = "LessThanThreshold"
          evaluation_periods  = "1"
          datapoints_to_alarm = "1"
          metric_name         = "DaysToExpiry"
          namespace           = "AWS/CertificateManager"
          period              = "86400"
          statistic           = "Minimum"
          threshold           = "5"
          alarm_description   = "Test alarm for ACM Cert"
        }
      }
      weblogic = local.ec2_weblogic_cloudwatch_metric_alarms
      database = local.database_cloudwatch_metric_alarms
    }
    cloudwatch_metric_alarms_lists = merge({
      acm_default = {
        parent_keys = []
        alarms_list = [
          { key = "acm", name = "cert-expiry-alarm-test" }
        ]
      } },
      local.ec2_weblogic_cloudwatch_metric_alarms_lists,
      local.database_cloudwatch_metric_alarms_lists
    )
    cloudwatch_metric_alarms_lists_with_actions = {
      nomis_alarm = ["nomis_pagerduty", "nomis_email"]
    }
    route53_resolver_rules = {
      outbound-data-and-private-subnets = ["azure-fixngo-domain"]
    }
    iam_policies_filter      = ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    iam_policies_ec2_default = ["EC2S3BucketWriteAndDeleteAccessPolicy", "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    s3_iam_policies          = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    sns_topics = {
      pagerduty_integrations = {
        nomis_pagerduty = contains(["development", "test"], local.environment) ? "nomis_nonprod_alarms" : "nomis_alarms"
      }
      emails = {
        nomis_email = "/monitoring/test"
      }
    }
  }
}

module "baseline_presets" {
  source = "../../modules/baseline_presets"

  environment  = module.environment
  ip_addresses = module.ip_addresses
  options      = local.baseline_presets_options
}

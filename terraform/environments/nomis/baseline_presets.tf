locals {

  dso_sns_topic_arn = contains(["development", "test"], local.environment) ? aws_sns_topic.nomis_nonprod_alarms.arn : aws_sns_topic.nomis_alarms.arn

  baseline_presets_options = {
    enable_application_environment_wildcard_cert = false
    enable_business_unit_kms_cmks                = true
    # enable_image_builder                         = true
    enable_ec2_cloud_watch_agent = true
    enable_ec2_self_provision    = true
    cloudwatch_metric_alarms = {
      weblogic = local.ec2_weblogic_cloudwatch_metric_alarms
      database = local.database_cloudwatch_metric_alarms
    }
    cloudwatch_metric_alarms_lists = merge(
      local.ec2_weblogic_cloudwatch_metric_alarms_lists,
      local.database_cloudwatch_metric_alarms_lists
    )
    # cloudwatch_metric_alarms_lists_with_actions = {
    #   dso = [local.dso_sns_topic_arn]
    # }
    route53_resolver_rules = {
      outbound-data-and-private-subnets = ["azure-fixngo-domain"]
    }
    iam_policies_filter      = ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    iam_policies_ec2_default = ["EC2S3BucketWriteAndDeleteAccessPolicy", "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    s3_iam_policies          = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    # sns_topics_pagerduty_integrations = {
    #   nomis_alarms         = "nomis_alarms"
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

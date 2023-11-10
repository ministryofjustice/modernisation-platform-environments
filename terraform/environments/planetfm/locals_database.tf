locals {

  database_ec2 = {
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_owner                     = "self"
      ebs_volumes_copy_all_from_ami = false
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      disable_api_termination = true
      disable_api_stop        = true
      monitoring              = true
      vpc_security_group_ids  = ["domain", "database", "jumpserver"]
      tags = {
        backup-plan         = "daily-and-weekly"
        instance-scheduling = "skip-scheduling"
      }
    })
    cloudwatch_metric_alarms = local.database_ec2_cloudwatch_metric_alarms
    tags = {
      os-type   = "Windows"
      component = "database"
    }
    route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external
  }

  database_ec2_cloudwatch_metric_alarms = merge(
    module.baseline_presets.cloudwatch_metric_alarms.ec2,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows
  )
}
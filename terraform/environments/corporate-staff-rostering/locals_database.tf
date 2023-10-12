locals {

  database_ssm_parameters = {
    parameters = {
      passwords = { description = "database passwords" }
    }
  }

  database_ec2_cloudwatch_metric_alarms = merge(
    module.baseline_presets.cloudwatch_metric_alarms.ec2,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux
  )

}

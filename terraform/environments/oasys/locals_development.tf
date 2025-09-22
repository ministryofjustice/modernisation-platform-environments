locals {

  baseline_presets_development = {
    options = {
      # disabling some features in development as the environment gets nuked
      cloudwatch_metric_oam_links_ssm_parameters = []
      cloudwatch_metric_oam_links                = []
    }
  }

  # please keep resources in alphabetical order
  baseline_development = {
  }

  data_subnets = [
    data.aws_subnet.data_subnets_a.id
  ]
cloudwatch_metric_alarms_endpoint_monitoring = [
  Decription = "Set the endpoint location"
  type = string
  ]
}

# nomis-development environment settings
locals {

  # cloudwatch monitoring config
  development_cloudwatch_monitoring_options = {}

  # baseline config
  development_config = {

    # example code for creating a cost usage report in the development environment
    # 
    # baseline_cost_usage_report = {
    #   create = true
    # }
  }
}

# CloudWatch Observability Access Manager
# The sink ID is stored in an SSM parameter

locals {
  oam_links = {
    for oam_link in coalesce(var.options.cloudwatch_metric_oam_links, []) : oam_link => {
      resource_types                     = ["AWS::CloudWatch::Metric"]
      sink_identifier_ssm_parameter_name = "/oam/${oam_link}"
    }
  }
}

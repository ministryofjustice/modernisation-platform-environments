# CloudWatch Observability Access Manager
# See baseline module oam.tf for documentation

locals {
  oam_links = {
    for oam_link in coalesce(var.options.cloudwatch_metric_oam_links, []) : oam_link => {
      label_template                     = var.environment.account_name
      resource_types                     = ["AWS::CloudWatch::Metric"]
      sink_identifier_ssm_parameter_name = "/oam/${oam_link}"
    }
  }
}

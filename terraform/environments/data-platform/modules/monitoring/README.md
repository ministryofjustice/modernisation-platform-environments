# Data Platform Monitoring Module

This Terraform module provisions the required IAM resources for the Data Platform's Grafana instanceto read CloudWatch, Prometheus, and X-Ray data from Data Platform AWS accounts.

## Usage

```hcl
module "data_platform_monitoring" {
  source = "./modules/monitoring"

  enable_cloudwatch_read_only_access    = true
  enable_amazon_prometheus_query_access = true
  enable_aws_xray_read_only_access      = true

  additional_policies = {
    # Add any additional custom policies here
  }

  tags = local.tags
}

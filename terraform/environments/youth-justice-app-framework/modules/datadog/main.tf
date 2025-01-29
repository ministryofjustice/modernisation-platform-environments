# Terraform 0.13+ uses the Terraform Registry:

terraform {
  required_providers {
    datadog = {
      source = "DataDog/datadog"
    }
  }
}

#data "aws_secretsmanager_secret" "datadog_api_key" {
#  name = "yjaf-datadog-api-key"
#}

#data "aws_secretsmanager_secret_version" "datadog_api_key" {
#  secret_id = data.aws_secretsmanager_secret.datadog_api_key.id
#}

# Configure the Datadog provider - https://registry.terraform.io/providers/DataDog/datadog/latest/docs
provider "datadog" {
  api_key = var.datadog_app_key
  app_key = var.datadog_app_key
}


# Create a new Datadog - Amazon Web Services integration
resource "datadog_integration_aws" "sandbox" {
  account_id  = var.account_id
  role_name   = "Yjaf-Datadog-AWS-Integration-Role"
  filter_tags = var.filter_tags
  account_specific_namespace_rules = {
    auto_scaling = false
    opsworks     = false
  }
  excluded_regions = ["us-east-1", "us-west-2"]
}

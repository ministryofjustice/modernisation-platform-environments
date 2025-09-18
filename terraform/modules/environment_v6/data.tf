#------------------------------------------------------------------------------
# Accounts
#------------------------------------------------------------------------------

data "aws_ssm_parameter" "modernisation_platform_account_id" {
  name = "modernisation_platform_account_id"
}

#------------------------------------------------------------------------------
# Environment
#------------------------------------------------------------------------------

# Get environment specific configuration
data "http" "environments_file" {
  url = "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform/main/environments/${var.application_name}.json"
}

#------------------------------------------------------------------------------
# Network
#------------------------------------------------------------------------------

data "aws_availability_zones" "this" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_vpc" "this" {
  tags = {
    Name = local.vpc_name
  }
}

data "aws_subnets" "this" {
  for_each = toset(local.subnet_names[var.subnet_set])

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  tags = {
    Name = "${local.vpc_name}-${var.subnet_set}-${each.key}-${var.region}*"
  }
}

data "aws_subnet" "this" {
  for_each = toset(flatten([
    for subnet_name in local.subnet_names[var.subnet_set] : [
      for zone_name in data.aws_availability_zones.this.names : "${subnet_name}-${zone_name}"
    ]
  ]))

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  tags = {
    Name = "${local.vpc_name}-${var.subnet_set}-${each.key}"
  }
}

data "aws_route53_zone" "core_network_services" {
  for_each = { for key, value in local.route53_zones : key => value if value.account == "core-network-services" }

  provider = aws.core-network-services

  name         = "${each.key}."
  private_zone = each.value.private_zone
}

data "aws_route53_zone" "core_vpc" {
  for_each = { for key, value in local.route53_zones : key => value if value.account == "core-vpc" }

  provider = aws.core-vpc

  name         = "${each.key}."
  private_zone = each.value.private_zone
}

#------------------------------------------------------------------------------
# KMS
#------------------------------------------------------------------------------

data "aws_kms_key" "this" {
  for_each = local.kms_keys
  key_id   = each.value
}

#------------------------------------------------------------------------------
# Pager Duty
#------------------------------------------------------------------------------

# Get the map of pagerduty integration keys from the modernisation platform account
data "aws_secretsmanager_secret" "pagerduty_integration_keys" {
  provider = aws.modernisation-platform
  name     = "pagerduty_integration_keys"
}

data "aws_secretsmanager_secret_version" "pagerduty_integration_keys" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.pagerduty_integration_keys.id
}

# Data source to get the ARN of an existing SNS topic
data "aws_sns_topic" "backup_failure_topic" {
  name = "backup_failure_topic"
}

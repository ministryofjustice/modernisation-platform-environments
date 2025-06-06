locals {
  # don't bother creating the firehose if the SSM param hasn't been populated outside of terraform
  data_firehoses = {
    for key, value in var.data_firehoses : key => value if !strcontains(nonsensitive(aws_ssm_parameter.placeholder[value.destination_http_endpoint_ssm_parameter_name].value), "placeholder")
  }
}

module "data_firehose" {
  for_each = local.data_firehoses

  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-data-firehose?ref=204ccb4d5160a83774fa9585d060ee925640426b" # v2.0.0

  cloudwatch_log_group_names   = each.value.cloudwatch_log_group_names
  destination_http_endpoint    = aws_ssm_parameter.placeholder[each.value.destination_http_endpoint_ssm_parameter_name].value
  destination_http_secret_name = each.value.destination_http_secret_name
  name                         = each.key

  tags = local.tags
}

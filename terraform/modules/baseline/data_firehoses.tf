locals {
  # don't bother creating the firehose if the SSM param hasn't been populated outside of terraform
  data_firehoses = {
    for key, value in var.data_firehoses : key => value if !strcontains(nonsensitive(aws_ssm_parameter.placeholder[value.destination_http_endpoint_ssm_parameter_name].value), "placeholder")
  }
}

module "data_firehose" {
  for_each = local.data_firehoses

  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-data-firehose?ref=1851b164e43db853ff45bb4393ec76b89cb0edbf"

  cloudwatch_log_group_names          = each.value.cloudwatch_log_group_names
  destination_http_endpoint           = aws_ssm_parameter.placeholder[each.value.destination_http_endpoint_ssm_parameter_name].value
  destination_http_apikey_secret_name = each.value.apikey_secret_name
  name                                = each.key

  tags = local.tags
}

data "aws_availability_zones" "available" {}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.eu-west-2.s3"

  depends_on = [module.isolated_vpc_endpoints]
}

data "aws_secretsmanager_secret_version" "slack_token" {
  secret_id = aws_secretsmanager_secret.slack_token.id
}

data "aws_secretsmanager_secret_version" "govuk_notify_api_key" {
  secret_id = aws_secretsmanager_secret.govuk_notify_api_key.id
}

data "aws_secretsmanager_secret_version" "govuk_notify_templates" {
  secret_id = aws_secretsmanager_secret.govuk_notify_templates.id
}

data "aws_ssm_parameter" "datasync_ami" {
  name = "/aws/service/datasync/ami"
}

data "external" "external_ip" {
  program = ["bash", "${path.module}/scripts/get-ip-address.sh"]
}

data "dns_a_record_set" "datasync_activation_nlb" {
  host = module.datasync_activation_nlb.dns_name
}

data "aws_network_interface" "datasync_vpc_endpoint" {
  id = tolist(module.connected_vpc_endpoints.endpoints["datasync"].network_interface_ids)[0]
}

data "aws_ec2_transit_gateway" "moj_tgw" {
  id = "tgw-026162f1ba39ce704"
}

data "aws_secretsmanager_secret_version" "datasync_dom1" {
  secret_id = module.datasync_dom1_secret.secret_id
}

data "aws_secretsmanager_secret_version" "datasync_exclude_path" {
  secret_id = module.datasync_exclude_path_secret.secret_id
}

data "aws_secretsmanager_secret_version" "datasync_include_paths" {
  secret_id = module.datasync_include_paths_secret.secret_id
}

data "aws_secretsmanager_secret_version" "laa_data_analysis_bucket_list" {
  count     = local.environment == "production" ? 1 : 0
  secret_id = module.laa_data_analysis_bucket_list[0].secret_id
}
data "aws_secretsmanager_secret_version" "laa_data_analysis_keys" {
  count     = local.environment == "production" ? 1 : 0
  secret_id = module.laa_data_analysis_keys[0].secret_id
}

data "aws_route53_resolver_query_log_config" "core_logging_s3" {
  filter {
    name   = "Name"
    values = ["core-logging-rlq-s3"]
  }
}

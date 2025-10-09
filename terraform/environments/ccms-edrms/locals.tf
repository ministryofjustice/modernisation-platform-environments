locals {
  data_subnets_cidr_blocks = [
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block
  ]

  private_subnets_cidr_blocks = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]

  app_vars = jsondecode(file("${path.module}/application_variables.json"))
  environment     = trimprefix(terraform.workspace, "${var.networking[0].application}-")

  edrms_secret_keys = local.app_vars.accounts[local.environment].edrms_secret_keys

  edrms_secret_values = {
    for key in local.edrms_secret_keys :
    key => try(local.app_vars.accounts[local.environment][replace(replace(key, "/", "_"), "-", "_")], null)
  }

  edrms_secret = jsondecode(data.aws_secretsmanager_secret_version.edrms_secret_version_current.secret_string)
  spring_datasource_password_arn = aws_secretsmanager_secret.edrms_secret.arn
  cert_opts    = aws_acm_certificate.external.domain_validation_options
  cert_arn     = aws_acm_certificate.external.arn
  cert_zone_id = data.aws_route53_zone.external.zone_id
}

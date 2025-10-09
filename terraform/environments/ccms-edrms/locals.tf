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

  edrms_secret = jsondecode(data.aws_secretsmanager_secret_version.edrms_secret_version.secret_string)
  spring_datasource_password_arn = aws_secretsmanager_secret.edrms_secret.arn
  rendered_json = templatefile("${path.module}/templates/task_definition_edrms.json.tpl", {
    spring_datasource_password = local.spring_datasource_password_arn
  })
  cert_opts    = aws_acm_certificate.external.domain_validation_options
  cert_arn     = aws_acm_certificate.external.arn
  cert_zone_id = data.aws_route53_zone.external.zone_id
}

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

  edrms_secret = jsondecode(data.aws_secretsmanager_secret_version.edrms_secret_version_current.secret_string)
  secret_arn = aws_secretsmanager_secret.edrms_secret.arn
  
  cert_opts    = aws_acm_certificate.external.domain_validation_options
  cert_arn     = aws_acm_certificate.external.arn
  cert_zone_id = data.aws_route53_zone.external.zone_id
}

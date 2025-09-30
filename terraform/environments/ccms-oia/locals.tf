#######################################
# Locals
#######################################

locals {
  # AWS region (from data source)
  aws_region = data.aws_region.current.id

  # Subnet CIDR blocks
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

  # Certificates (used by ALB/Ingress)
  cert_opts    = aws_acm_certificate.external.domain_validation_options
  cert_arn     = aws_acm_certificate.external.arn
  cert_zone_id = data.aws_route53_zone.external.zone_id


  # Build datasource URL for MySQL RDS
  spring_datasource_url = "jdbc:mysql://${aws_db_instance.oia_db.address}:3306/oia"
}

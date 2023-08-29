resource "aws_vpc_endpoint" "this" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.execute-api"
  private_dns_enabled = true
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  vpc_endpoint_type   = "Interface"

  tags = var.tags
}
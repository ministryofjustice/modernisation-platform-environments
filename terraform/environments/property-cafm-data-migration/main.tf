module "rds_export" {
  source = "github.com/ministryofjustice/terraform-rds-export?ref=sql-backup-restore"

  # Replace the kms_key_arn, name, vpc_id and (database_subnet_ids in a list)
  kms_key_arn = aws_kms_key.sns_kms.arn
  name =local.application_name
  vpc_id = module.vpc.vpc_id
  database_subnet_ids = module.vpc.private_subnets

  tags = {
    business-unit = "Property"
    application   = local.application_name
    is-production = "false"
    owner         = "shanmugapriya.basker@justice.gov.uk"
  }
}

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = {
    Name = "${local.application_name}-s3-endpoint"
  }
}

# Secrets Manager Interface Endpoint
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.vpc.default_security_group_id] # or your custom SG

  private_dns_enabled = true

  tags = {
    Name = "${local.application_name}-secretsmanager-endpoint"
  }
}

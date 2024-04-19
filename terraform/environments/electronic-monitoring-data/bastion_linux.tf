locals {
  public_key_data = jsondecode(file("${path.module}/bastion_linux.json"))
}

# tfsec:ignore:aws-s3-enable-bucket-encryption tfsec:ignore:aws-s3-encryption-customer-key tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning
module "rds_bastion" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux?ref=v4.2.0"

  providers = {
    aws.share-host   = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
    aws.share-tenant = aws          # The default provider (unaliased, `aws`) is the tenant
  }

  # s3 - used for logs and user ssh public keys
  bucket_name = "rds-bastion"

  # public keys
  public_key_data = local.public_key_data.keys[local.environment]

  # logs
  log_auto_clean       = "Enabled"
  log_standard_ia_days = 30  # days before moving to IA storage
  log_glacier_days     = 60  # days before moving to Glacier
  log_expiry_days      = 180 # days before log expiration

  # bastion
  allow_ssh_commands = true

  app_name      = var.networking[0].application
  business_unit = local.vpc_name
  subnet_set    = local.subnet_set
  environment   = local.environment
  region        = "eu-west-2"

  # tags
  tags_common = local.tags
  tags_prefix = terraform.workspace
}

resource "aws_vpc_security_group_egress_rule" "access_ms_sql_server" {
  security_group_id = module.rds_bastion.bastion_security_group
  description       = "EC2 MSSQL Access"
  ip_protocol       = "tcp"
  from_port         = 1433
  to_port           = 1433
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "rds_via_vpc_access" {
  security_group_id = aws_security_group.db.id
  description       = "EC2 instance connection to RDS"
  ip_protocol       = "tcp"
  from_port         = 1433
  to_port           = 1433
  referenced_security_group_id = module.rds_bastion.bastion_security_group
}

locals {
  public_key_data = jsondecode(file("./bastion_linux.json"))
}

#tfsec:ignore:aws-s3-encryption-customer-key:exp:2022-08-31 tfsec:ignore:aws-s3-enable-bucket-logging:exp:2022-08-31 these checks are ignored in the bastion module but don't proagate through
module "bastion_linux" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux?ref=v3.0.4"

  providers = {
    aws.share-host   = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
    aws.share-tenant = aws          # The default provider (unaliased, `aws`) is the tenant
  }

  # s3 - used for logs and user ssh public keys
  bucket_name          = "bastion"
  bucket_versioning    = true
  bucket_force_destroy = true
  # public keys
  public_key_data = local.public_key_data.keys[local.environment]
  # logs
  log_auto_clean       = "Enabled"
  log_standard_ia_days = 30  # days before moving to IA storage
  log_glacier_days     = 60  # days before moving to Glacier
  log_expiry_days      = 180 # days before log expiration
  # bastion
  allow_ssh_commands = false

  app_name      = var.networking[0].application
  business_unit = local.vpc_name
  subnet_set    = local.subnet_set
  environment   = local.environment
  region        = "eu-west-2"

  # Tags
  tags_common = merge(
    local.tags,
    {
      os_type = "Linux"
    }
  )
  tags_prefix = terraform.workspace
}

resource "aws_security_group_rule" "CP_monitoring_ingress" {
  description       = "Allows access from Cloud Platform Monitoring"
  type              = "ingress"
  from_port         = 9100
  to_port           = 9100
  protocol          = "tcp"
  cidr_blocks       = [local.accounts[local.environment].database_external_access_cidr.cloud_platform]
  security_group_id = module.bastion_linux.bastion_security_group
}

resource "aws_security_group_rule" "CP_monitoring_egress" {
  description       = "Allows access from Cloud Platform Monitoring"
  type              = "egress"
  from_port         = 9100
  to_port           = 9100
  protocol          = "tcp"
  cidr_blocks       = [local.accounts[local.environment].database_external_access_cidr.cloud_platform]
  security_group_id = module.bastion_linux.bastion_security_group
}

##
# Create bastion server from module
##
locals {
  public_key_data = jsondecode(file("./bastion_linux.json"))
}

# tfsec:ignore:aws-s3-enable-bucket-encryption tfsec:ignore:aws-s3-encryption-customer-key tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning
module "bastion_linux" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux?ref=v5.0.0"

  providers = {
    aws.share-host   = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
    aws.share-tenant = aws          # The default provider (unaliased, `aws`) is the tenant
  }

  instance_name = "bastion-${var.env_name}"

  # s3 - used for logs and user ssh public keys
  bucket_name = "bastion-${var.env_name}"
  # public keys
  public_key_data = local.public_key_data.keys[var.env_name]
  # logs
  log_auto_clean       = "Enabled"
  log_standard_ia_days = 30  # days before moving to IA storage
  log_glacier_days     = 60  # days before moving to Glacier
  log_expiry_days      = 180 # days before log expiration
  # bastion
  allow_ssh_commands = false

  app_name      = var.app_name
  business_unit = var.bastion_config.business_unit
  subnet_set    = var.bastion_config.subnet_set
  environment   = var.bastion_config.environment
  region        = "eu-west-2"

  extra_user_data_content = var.bastion_config.extra_user_data_content
  # Tags
  tags_common = var.tags
  tags_prefix = terraform.workspace
}


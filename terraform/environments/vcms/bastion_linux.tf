locals {
  public_key_data = jsondecode(file("./files/bastion_linux.json"))
}

module "bastion_linux" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux?ref=v5.0.0"

  providers = {
    aws.share-host   = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
    aws.share-tenant = aws          # The default provider (unaliased, `aws`) is the tenant
  }

  instance_name = "bastion-${local.environment}"

  # s3 - used for logs and user ssh public keys
  bucket_name = "bastion-${local.environment}"
  # public keys
  public_key_data = local.public_key_data.keys[local.environment]
  # logs
  log_auto_clean       = "Enabled"
  log_standard_ia_days = 30  # days before moving to IA storage
  log_glacier_days     = 60  # days before moving to Glacier
  log_expiry_days      = 180 # days before log expiration
  # bastion
  allow_ssh_commands = false

  app_name      = local.application_name
  business_unit = local.account_info.business_unit
  subnet_set    = local.subnet_set
  environment   = local.environment
  region        = "eu-west-2"

  extra_user_data_content = ""
  # Tags
  tags_common = local.tags
  tags_prefix = terraform.workspace
}

module "bastion_linux" {
  count = var.bastion_linux != null ? 1 : 0

  source = "github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux?ref=v3.0.8"

  providers = {
    aws.share-host   = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
    aws.share-tenant = aws          # The default provider (unaliased, `aws`) is the tenant
  }

  # s3 - used for logs and user ssh public keys
  bucket_name          = var.bastion_linux.bucket_name
  bucket_versioning    = var.bastion_linux.bucket_versioning
  bucket_force_destroy = var.bastion_linux.bucket_force_destroy

  # public keys
  public_key_data = var.bastion_linux.public_key_data

  # logs
  log_auto_clean       = var.bastion_linux.log_auto_clean
  log_standard_ia_days = var.bastion_linux.log_standard_ia_days
  log_glacier_days     = var.bastion_linux.log_glacier_days
  log_expiry_days      = var.bastion_linux.log_expiry_days

  # bastion
  allow_ssh_commands = var.bastion_linux.allow_ssh_commands

  app_name                = var.environment.application_name
  business_unit           = var.environment.business_unit
  subnet_set              = var.environment.subnet_set
  environment             = var.environment.environment
  region                  = var.environment.region
  extra_user_data_content = var.bastion_linux.extra_user_data_content
  tags_common             = merge(local.tags, var.bastion_linux.tags)
  tags_prefix             = terraform.workspace
}

locals {
  public_key_data = jsondecode(file("./bastion_linux.json"))
  crontab = {
    "down" = "30 01 25 12 *"
    "up"   = "00 08 25 12 *"
  }
}

module "bastion_linux" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux?ref=V4.5.0"

  providers = {
    aws.share-host   = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
    aws.share-tenant = aws          # The default provider (unaliased, `aws`) is the tenant
  }
  # s3 - used for logs and user ssh public keys
  bucket_name = "bastion-${local.application_name_short}"
  # public keys
  public_key_data = local.public_key_data.keys[local.environment]
  # logs
  log_auto_clean       = "Enabled"
  log_standard_ia_days = 30  # days before moving to IA storage
  log_glacier_days     = 60  # days before moving to Glacier
  log_expiry_days      = 180 # days before log expiration
  # bastion
  allow_ssh_commands = false
  app_name           = var.networking[0].application
  business_unit      = local.vpc_name
  subnet_set         = local.subnet_set
  environment        = local.environment
  region             = "eu-west-2"
  # Autoscaling
  autoscaling_cron = local.crontab

  # Tags
  tags_common = local.tags
  tags_prefix = terraform.workspace
}

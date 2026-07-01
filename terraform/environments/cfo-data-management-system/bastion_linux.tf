locals {
  # SSH public keys
  public_key_data = jsondecode(file("./bastion_linux.json"))
}

# MP Bastion Linux module - https://github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux
module "bastion_linux" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux?ref=e4a3840d4b7b327228d1397bb684bc79cd4e76cb" # v4.5.0

  providers = {
    aws.share-host   = aws.core-vpc
    aws.share-tenant = aws
  }

  bucket_name          = "bastion"
  public_key_data      = local.public_key_data.keys[local.environment]
  log_auto_clean       = "Enabled"
  log_standard_ia_days = 30
  log_glacier_days     = 60
  log_expiry_days      = 180
  allow_ssh_commands   = false

  app_name      = var.networking[0].application
  business_unit = local.vpc_name
  subnet_set    = local.subnet_set
  environment   = local.environment
  region        = "eu-west-2"

  tags_common = local.tags
  tags_prefix = terraform.workspace
}

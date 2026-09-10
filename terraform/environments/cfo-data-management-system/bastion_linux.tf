locals {
  public_key_data = jsondecode(file("./bastion_linux.json"))
}

# MP Bastion Linux module - https://github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux
module "bastion_linux" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux?ref=9657c1df83514ad5cb17a02254d0bd91c8e30ef5" # v6.0.1

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

  tags_common = {
    for k, v in local.tags : k => v
    if k != "source-code"
  }
  tags_prefix = terraform.workspace
}

locals {
  # SSH public keys
  public_key_data = jsondecode(file("./bastion_linux.json"))

  # Trimmed tags due to S3 Objects limit of 10 tags
  bastion_tags = {
    application            = local.tags["application"]
    business-unit          = local.tags["business-unit"]
    environment-name       = local.tags["environment-name"]
    infrastructure-support = local.tags["infrastructure-support"]
    is-production          = tostring(local.is-production)
    owner                  = local.tags["owner"]
    service-area           = local.tags["service-area"]
  }
}

# MP Bastion Linux module - https://github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux
module "bastion_linux" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux?ref=29c5908bd41b183808fe0c02d9ae06f0ede2036b" # v6.0.0

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

  tags_common = local.bastion_tags
  tags_prefix = terraform.workspace
}

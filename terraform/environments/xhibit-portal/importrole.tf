module "vm-import" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-vm-import?ref=412c8e6d7a4c33c51c9ad6fa739857e64f405804"

  bucket_prefix    = local.application_data.accounts[local.environment].bucket_prefix
  tags             = local.tags
  application_name = local.application_name
  account_number   = local.environment_management.account_ids[terraform.workspace]

}

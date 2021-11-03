module "vm-import" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-vm-import"

  bucket_prefix    = local.application_data.accounts[local.environment].bucket_prefix
  tags             = local.tags
  application_name = local.application_name

}

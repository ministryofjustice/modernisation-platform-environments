module "vm-import" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-vm-import?ref=81c1edc3dd0f5f55c965bc83f4b71da4431f1c21"

  bucket_prefix    = local.application_data.accounts[local.environment].bucket_prefix
  tags             = local.tags
  application_name = local.application_name

}

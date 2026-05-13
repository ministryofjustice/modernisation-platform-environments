module "vm-import" {
  # checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash"
  # checkov:skip=CKV_TF_2: "Ensure Terraform module sources use a tag with a version number"
  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-vm-import?ref=bd592550a2ce393c165693660877e405b0328c0b" # v3.0.0

  bucket_prefix    = local.application_data.accounts[local.environment].bucket_prefix
  tags             = local.tags
  application_name = local.application_name
  account_number   = local.environment_management.account_ids[terraform.workspace]

}

module "vm-import" {
  # checkov:skip=CKV_TF_1: "Ensure Terraform module sources use a commit hash"
  # checkov:skip=CKV_TF_2: "Ensure Terraform module sources use a tag with a version number"
  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-vm-import?ref=abbfa64bfdb17540733d06864ef399dd5e7ceb22" # v3.1.0

  providers = {
    aws.bucket-replication = aws # replication_enabled = false, alias required by module
  }

  bucket_prefix    = local.application_data.accounts[local.environment].bucket_prefix
  tags             = local.tags
  application_name = local.application_name
  account_number   = local.environment_management.account_ids[terraform.workspace]

}

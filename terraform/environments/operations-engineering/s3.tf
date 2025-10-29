
# GitHub repositories Terraform state bucket

module "github_repos_tfstate_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket = "github-repos-tfstate-bucket"

  force_destroy = true

  attach_deny_insecure_transport_policy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.github_repos_s3_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

# Auth0 Terraform state bucket

module "auth0_tfstate_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket = "auth0-tfstate-bucket"

  force_destroy = true

  attach_deny_insecure_transport_policy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.auth0_s3_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
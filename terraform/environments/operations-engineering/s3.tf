# CUR v2 bucket

module "cur_v2_hourly" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket = "cur-v2-hourly"

  force_destroy = true

  attach_deny_insecure_transport_policy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.cur_s3_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

module "gpx_output_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket = "gpx-cur-output-bucket"

  force_destroy = true

  attach_deny_insecure_transport_policy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.gpx_s3_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

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

module "cur_v2_hourly_replication_test" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "github.com/ministryofjustice/aws-root-account/modules/s3?ref=main"

  bucket_name= "cur-v2-hourly-replication-test"
  enable_versioning = true
  enable_replication     = true
  replication_bucket_arn = "arn:aws:s3:::coat-development-test-replication-cur-v2-hourly"
  replication_role_arn   = module.cur_v2_hourly_replication_test.replication_role_arn
  destination_kms_arn    = "arn:aws:kms:eu-west-2:279191903737:key/ef7e1dc9-dc2b-4733-9278-46885b7040c7"
  replication_rules = [
    {
      id                 = "test-replicate-curv2-reports"
      prefix             = "moj-cost-and-usage-reports/"
      status             = "Enabled"
      deletemarker       = "Enabled"
      replica_kms_key_id = "arn:aws:kms:eu-west-2:279191903737:key/ef7e1dc9-dc2b-4733-9278-46885b7040c7"
      metrics            = "Enabled"
    }
  ]
}
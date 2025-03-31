# CUR v2 bucket

data "aws_iam_policy_document" "s3_root_account_write_policy" {
  #checkov:skip=CKV_AWS_356:resource "*" limited by condition
  statement {
    sid       = "s3_root_account_write_policy"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::cur-v2-hourly/*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.aws_organizations_root_account_id}:root"]
    }
  }
}

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
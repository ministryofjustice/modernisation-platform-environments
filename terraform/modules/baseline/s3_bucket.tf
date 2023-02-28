locals {

  # get list of policy names
  s3_buckets_iam_policy_names = distinct(flatten([
    for s3_key, s3_value in var.s3_buckets : keys(s3_value.iam_policies)
  ]))

  # form s3 bucket statements per policy
  s3_buckets_iam_policies = {
    for policy_name in local.s3_buckets_iam_policy_names : policy_name => {
      description = "Allows access to S3 bucket"
      path        = "/"
      statements = flatten([
        for s3_key, s3_value in var.s3_buckets : [
          for policy_key, policy_value in s3_value.iam_policies : [
            for statement in policy_value : merge(statement, {
              resources = [
                module.s3_bucket[s3_key].bucket.arn,
                "${module.s3_bucket[s3_key].bucket.arn}/*"
              ]
            })
          ] if policy_key == policy_name
        ]
      ])
    }
  }
}

module "s3_bucket" {
  for_each = var.s3_buckets

  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=feature/one-pass-custom-bucket-policy"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix              = each.key
  acl                        = each.value.acl
  versioning_enabled         = each.value.versioning_enabled
  replication_enabled        = each.value.replication_enabled
  replication_region         = coalesce(each.value.replication_region, var.environment.region)
  bucket_policy              = each.value.bucket_policy
  custom_kms_key             = coalesce(each.value.custom_kms_key, var.environment.kms_keys["general"].arn)
  custom_replication_kms_key = coalesce(each.value.custom_replication_kms_key, var.environment.kms_keys["general"].arn)
  lifecycle_rule             = each.value.lifecycle_rule
  log_bucket                 = each.value.log_bucket
  log_prefix                 = each.value.log_prefix
  replication_role_arn       = each.value.replication_role_arn
  force_destroy              = each.value.force_destroy
  sse_algorithm              = each.value.sse_algorithm

  tags = merge(local.tags, each.value.tags)
}

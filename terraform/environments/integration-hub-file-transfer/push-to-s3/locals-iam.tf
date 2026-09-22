locals {
  delivery_role_arns_by_secret = {
    for entry_id, secret_arn_prefix in local.push_to_s3_secret_arn_prefixes :
    secret_arn_prefix => module.iam_role_delivery[entry_id].arn
  }
}
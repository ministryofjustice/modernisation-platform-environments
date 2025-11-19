locals {

  environment_name = "${var.project_name}-${var.environment}"

  bucket_name          = formatlist("${local.environment_name}-%s", var.bucket_name)
  archive_bucket_name  = formatlist("${local.environment_name}-%s-archive", var.archive_bucket_name)
  transfer_bucket_name = formatlist("${local.environment_name}-%s", var.transfer_bucket_name)

  bucket_name_allow_replication = concat(local.archive_bucket_name, local.transfer_bucket_name)
  bucket_name_all               = concat(local.bucket_name, local.bucket_name_allow_replication)

  cors_buckets = [for b in var.bucket_name : b if contains(keys(var.cors_policy_map), b)]
}

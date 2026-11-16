locals {
  clean_bucket_name = "${local.application_name}-${local.environment}-clean"

  source_object_arns = [
    for entry in values(local.push_to_s3_entries) :
    "${data.aws_s3_bucket.clean.arn}/${entry.identity}${entry.source_prefix}*"
  ]
}
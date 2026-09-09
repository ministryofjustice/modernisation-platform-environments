locals {
  account_id      = data.aws_caller_identity.current.account_id
  region          = data.aws_region.current.region
  cloudtrail_name = "${var.bucket_prefix}-cloudtrail"
  cloudtrail_arn  = "arn:aws:cloudtrail:${data.aws_region.current.region}:${local.account_id}:trail/${local.cloudtrail_name}"

  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
    }
  )
}

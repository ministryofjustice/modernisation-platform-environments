locals {

  aws_account_id = data.aws_caller_identity.current.account_id


  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      Region    = data.aws_region.current.region
    }
  )
}
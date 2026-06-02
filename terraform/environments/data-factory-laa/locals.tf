locals {
  current_account_id     = data.aws_caller_identity.current.account_id
  current_account_region = data.aws_region.current.region
}
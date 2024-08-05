data "terraform_remote_state" "get_dms_s3_bucket_info" {
  for_each = toset(var.delius_account_names)
  backend  = "s3"
  config   = {
    bucket = "modernisation-platform-terraform-state"
    key    = "environments/members/delius-core/${each.key}/terraform.tfstate"
    region = var.account_info.region
  }
}

locals {
  dms_s3_bucket_list = [for account_name in var.delius_account_names : try(data.terraform_remote_state.get_dms_s3_bucket_info[account_name].outputs.dms_s3_bucket_info.dms_s3_bucket_name,null) ]

  dms_s3_cross_account_bucket_names = merge([
    for bucket_map in local.dms_s3_bucket_list : bucket_map
  ]...)

  dms_s3_role_exists = {for account_name in var.delius_account_names : account_name => try(data.terraform_remote_state.get_dms_s3_bucket_info[account_name].outputs.dms_s3_bucket_info.dms_s3_role_arn,null) == null ? false : true }

}


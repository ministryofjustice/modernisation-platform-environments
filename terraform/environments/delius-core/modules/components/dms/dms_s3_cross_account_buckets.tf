data "terraform_remote_state" "get_dms_s3_bucket_for_delius_core_development" {
  backend = "s3"
  config = {
    bucket = "modernisation-platform-terraform-state"
    key    = "environments/members/delius-core/delius-core-development/terraform.tfstate"
    region = "eu-west-2"
  }
}

output "delius_core_development_bucket_name" {
  value = data.terraform_remote_state.get_dms_s3_bucket_for_delius_core_development.outputs.dms_s3_bucket_name
}

data "terraform_remote_state" "get_dms_s3_bucket_for_delius_core_test" {
  backend = "s3"
  config = {
    bucket = "modernisation-platform-terraform-state"
    key    = "environments/members/delius-core/delius-core-test/terraform.tfstate"
    region = "eu-west-2"
  }
}

output "delius_core_test_bucket_name" {
  value = data.terraform_remote_state.get_dms_s3_bucket_for_delius_core_test.outputs.dms_s3_bucket_name
}


locals {
   dms_s3_bucket_names = {
    "development" = data.terraform_remote_state.get_dms_s3_bucket_for_delius_core_development.outputs.dms_s3_bucket_name
    "test" = data.terraform_remote_state.get_dms_s3_bucket_for_delius_core_test.outputs.dms_s3_bucket_name
   }
}

output "dms_s3_bucket_names" {
  value = local.dms_s3_bucket_names
}

data "terraform_remote_state" "get_dms_s3_buckets" {
  for_each = toset(var.delius_account_names)
  backend  = "s3"
  config   = {
    bucket = "modernisation-platform-terraform-state"
    key    = "environments/members/delius-core/${each.key}/terraform.tfstate"
    region = var.account_info.region
  }
}

locals {
  dms_s3_bucket_list = [for account_name in var.delius_account_names : try(data.terraform_remote_state.get_dms_s3_buckets[account_name].outputs.dms_s3_bucket_name,null) ]

  dms_s3_bucket_info = merge([
    for bucket_map in local.dms_s3_bucket_list : bucket_map
  ]...)
}

output "dms_s3_bucket_info" {
  value = local.dms_s3_bucket_info
}
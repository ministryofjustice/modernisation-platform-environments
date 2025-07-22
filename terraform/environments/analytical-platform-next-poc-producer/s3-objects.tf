locals {
  headcount_and_payroll_data_folder_prefix = "moj-headcount-and-payroll-data"
  headcount_and_payroll_data = {
    # https://www.gov.uk/government/publications/workforce-management-information-moj
    january-2022 = {
      url = "https://assets.publishing.service.gov.uk/media/623d8fbae90e075f0993a127/MoJ_headcount_and_payroll_data_for_January_2022.csv"
    }
    february-2022 = {
      url = "https://assets.publishing.service.gov.uk/media/62726dabd3bf7f0e7c249f0a/moj-headcount-and-payroll-data-february-2022.csv"
    }
    march-2022 = {
      url = "https://assets.publishing.service.gov.uk/media/628c9a26e90e071f63e2563d/moj-headcount-payroll-data-march-2022.csv"
    }
  }
}

data "http" "moj_headcount_and_payroll_data" {
  for_each = local.headcount_and_payroll_data

  url = each.value.url
}

module "moj_headcount_and_payroll_data_s3_objects" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  for_each = local.headcount_and_payroll_data

  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "5.2.0"

  bucket             = module.s3_bucket.s3_bucket_id
  key                = "${local.headcount_and_payroll_data_folder_prefix}/${each.key}.csv"
  content            = data.http.moj_headcount_and_payroll_data[each.key].response_body
  bucket_key_enabled = true
  force_destroy      = true
}

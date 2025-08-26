locals {
  data_folder_prefix = "moj"
  data = {
    # https://www.data.gov.uk/dataset/7e62854a-2926-4f86-bdfb-b88c0800c628/court-locations
    court-locations = {
      url = "https://factprod.blob.core.windows.net/csv/courts-and-tribunals-data.csv"
    }
  }
}

data "http" "data" {
  for_each = local.data

  url = each.value.url
}

module "data_s3_objects" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  for_each = local.data

  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "5.6.0"

  bucket             = module.mojap_next_poc_data_s3_bucket.s3_bucket_id
  key                = "${local.data_folder_prefix}/${each.key}.csv"
  content            = data.http.data[each.key].response_body
  bucket_key_enabled = true
  force_destroy      = true
}

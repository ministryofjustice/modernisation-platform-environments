module "data_s3_objects" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  for_each = { for prefix in local.s3_prefixes : "${prefix.database}/${prefix.table}" => prefix }

  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "5.7.0"

  bucket             = module.mojap_next_poc_data_s3_bucket.s3_bucket_id
  key                = "${each.value.database}/${each.value.table}/data.csv"
  content            = data.http.test_data_csv.response_body
  bucket_key_enabled = true
  force_destroy      = true
}

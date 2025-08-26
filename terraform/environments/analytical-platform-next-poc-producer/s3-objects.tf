# locals {
#   gds_data_folder_prefix = "gds"
#   gds_data = {
#     # https://www.data.gov.uk/dataset/a0abdb2c-f210-4f07-bb36-9ff553bf4a23/local-authority-services
#     local-authority-services = {
#       url = "https://govuk-app-assets-production.s3.eu-west-1.amazonaws.com/data/local-links-manager/links_to_services_provided_by_local_authorities.csv"
#     }
#   }
# }

# data "http" "gds_data" {
#   for_each = local.gds_data

#   url = each.value.url
# }

# module "gds_data_s3_objects" {
#   #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
#   #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

#   for_each = local.gds_data

#   source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
#   version = "5.6.0"

#   bucket             = module.mojap_next_poc_data_s3_bucket.s3_bucket_id
#   key                = "${local.gds_data_folder_prefix}/${each.key}.csv"
#   content            = data.http.gds_data[each.key].response_body
#   bucket_key_enabled = true
#   force_destroy      = true
# }

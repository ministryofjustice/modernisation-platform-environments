# resource "aws_lakeformation_permissions" "allow_consumer_associate_tag" {
#   principal   = local.hub_account_id
#   permissions = ["ASSOCIATE"]

#   lf_tag {
#     key    = "business-unit"
#     values = ["Central Digital"]
#   }
# }

# resource "aws_lakeformation_permissions" "share_table_access" {
#   principal   = local.hub_account_id
#   permissions = ["SELECT", "DESCRIBE"]

#   lf_tag_policy {
#     resource_type = "TABLE"
#     expression {
#       key    = "business-unit"
#       values = ["Central Digital"]
#     }
#   }
# }

# resource "aws_lakeformation_permissions" "share_data_location" {
#   principal   = local.hub_account_id
#   permissions = ["DATA_LOCATION_ACCESS"]

#   data_location {
#     arn = module.mojap_next_poc_data_s3_bucket.s3_bucket_arn
#   }
# }

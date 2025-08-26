# RETIRED
# resource "aws_glue_crawler" "gds_data" {
#   name                   = "gds-data"
#   database_name          = aws_glue_catalog_database.gds_data.name
#   role                   = module.glue_crawler_iam_role.iam_role_name
#   security_configuration = aws_glue_security_configuration.main.name

#   s3_target {
#     path = "s3://${module.mojap_next_poc_data_s3_bucket.s3_bucket_id}/${local.gds_data_folder_prefix}"
#   }
# }

# RETIRED
# resource "aws_glue_data_catalog_encryption_settings" "main" {
#   data_catalog_encryption_settings {
#     connection_password_encryption {
#       aws_kms_key_id                       = module.glue_connections_kms_key.key_arn
#       return_connection_password_encrypted = true
#     }
#     encryption_at_rest {
#       catalog_encryption_mode = "SSE-KMS"
#       sse_aws_kms_key_id      = module.glue_catalog_kms_key.key_arn
#     }
#   }
# }

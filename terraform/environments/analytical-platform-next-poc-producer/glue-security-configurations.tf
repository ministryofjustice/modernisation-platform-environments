# RETIRED
# resource "aws_glue_security_configuration" "main" {
#   name = "main"

#   encryption_configuration {
#     cloudwatch_encryption {
#       cloudwatch_encryption_mode = "SSE-KMS"
#       kms_key_arn                = module.glue_crawler_logs_kms_key.key_arn
#     }

#     job_bookmarks_encryption {
#       job_bookmarks_encryption_mode = "CSE-KMS"
#       kms_key_arn                   = module.glue_catalog_kms_key.key_arn
#     }

#     s3_encryption {
#       s3_encryption_mode = "SSE-KMS"
#       kms_key_arn        = module.glue_catalog_kms_key.key_arn
#     }
#   }
# }

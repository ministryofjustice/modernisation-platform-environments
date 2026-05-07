resource "aws_macie2_account" "macie_unstructured_spike" {
  count  = local.is-development ? 1 : 0
  status = "ENABLED"
}


# Uses the default checks
# resource "aws_macie2_classification_job" "unstructured_data_spike" {
#   depends_on = [aws_macie2_account.macie_unstructured_spike]

#   name        = "spike-unstructured-data"
#   description = "Spike to scan unstructured data"

#   job_type    = "ONE_TIME" 

#   s3_job_definition {
#     bucket_definitions {
#       account_id = data.aws_caller_identity.current.account_id
#       buckets    = [module.s3-data-bucket.bucket.id]
#     }

#     scoping {
#       includes {
#         and {
#           simple_scope_term {
#             comparator = "STARTS_WITH"
#             key        = "OBJECT_KEY"
#             values     = ["g4s/atrium_unstructured/2024-05-31/340000-1349999"]
#           }
#         }
#       }
#     }
#   }
# }

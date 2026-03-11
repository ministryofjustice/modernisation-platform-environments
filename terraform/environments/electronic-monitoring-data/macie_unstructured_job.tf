resource "aws_macie2_account" "macie_unstructured_spike" {
  status = "PAUSED"
}


# Uses the default checks
# resource "aws_macie2_classification_job" "unstructured_data_spike" {
#   depends_on = [aws_macie2_account.macie_unstructured_spike]

#   name        = "spike-unstructured-data"
#   description = "Spike to scan unstructured data"
  
#   job_type    = "ONE_TIME" 
  
#   # For custom jobs add the arn values for each custom ident
#   # custom_ident_ids = [aws_macie2_custom_data_identifier.my_regex.id]

#   s3_job_definition {
#     bucket_definitions {
#       account_id = data.aws_caller_identity.current.account_id
#       buckets    = [module.s3-data-bucket.bucket.id]
#     }
    
#     scoping {
#       includes {
#         and {
#           # Only scan objects in this prefix
#           simple_scope_term {
#             comparator = "STARTS_WITH"
#             key        = "OBJECT_KEY"
#             values     = ["g4s/atrium_unstructured/2024-05-31/340000-1349999"]
#           }
#         }
#         and {
#           simple_scope_term {
#             comparator = "EQ"
#             key        = "OBJECT_EXTENSION"
#             values     = ["zip"]
#           }
#         }
#       }
#     }
#   }
# }

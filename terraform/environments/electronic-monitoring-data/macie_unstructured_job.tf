resource "aws_macie2_account" "macie_unstructured_spike" {
  status = "ENABLED"
}

resource "aws_macie2_classification_job" "unstructured_data_spike_atrium" {
  depends_on = [aws_macie2_account.macie_unstructured_spike]

  name_prefix = "spike-unstructured-data-atrium-"
  description = "Spike to scan unstructured data"
  
  # ONE TIME IS CONSIDERED ONCE AND DONE 
  job_type    = "ONE_TIME" 
  
  # For custom jobs add the arn values for each custom ident
  # custom_ident_ids = [aws_macie2_custom_data_identifier.my_regex.id]

  s3_job_definition {
    bucket_definitions {
      account_id = data.aws_caller_identity.current.account_id
      buckets    = [module.s3-data-bucket.bucket.id]
    }
    
    scoping {
      includes {
        and {
          # Only scan objects in this prefix
          simple_scope_term {
            comparator = "STARTS_WITH"
            key        = "OBJECT_KEY"
            values     = ["g4s/atrium_unstructured/2024-05-31"]
          }
        }
        and {
          simple_scope_term {
            comparator = "EQ"
            key        = "OBJECT_EXTENSION"
            values     = ["zip"]
          }
        }
      }
    }
  }
}


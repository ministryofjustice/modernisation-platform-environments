# WOW WHAT'S QUICKSIGHT DOING HERE?! 
# This will be moved into analytical-platform-compute 
# I can't plan in there effectively at the moment as there is ongoing work :shrug: 

# Out of Scope: 
# - QuickSight Dashboards
# - QuickSight DataSets

# In Scope:
# - QuickSight Account Subscription
# - QuickSight DataSources
#   - S3 Data Source
#   - Athena Data Source
#   - Glue Data Source

resource "aws_quicksight_account_subscription" "subscription" {
  account_name          = data.aws_caller_identity.current.account_id
  authentication_method = "IAM_IDENTITY_CENTER"
  edition               = "STANDARD"
  notification_email    = local.environment_configuration.notification_email
}

resource "aws_iam_role" "quicksight" {
  name = "quicksight-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "quicksight.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_quicksight_data_source" "s3" {
  data_source_id = "s3"
  name           = "S3 QuickSight Data Source"

  parameters {
    s3 {
      manifest_file_location {
        bucket = "bucket-name"
        key    = "path/to/manifest.json"
      }
    }
  }

  type = "S3"
}

resource "aws_quicksight_data_source" "athena" {
  data_source_id = "athena"
  name           = "Athena QuickSight Data Source"

  parameters {
    athena {
      work_group = "primary"
    }
  }

  type = "ATHENA"
}


# resource "aws_quicksight_data_source" "glue" {
#   data_source_id = "glue"
#   name           = "Glue QuickSight Data Source"

#   parameters {
#   }
# }

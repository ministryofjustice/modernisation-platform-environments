# a cloudtrail trail to save log files for putObject S3 events in the landing and data
# buckets
resource "aws_cloudtrail" "data_s3_put_objects" {
  name           = "data_platform_s3_putobject_trail_${local.environment}"
  s3_bucket_name = module.logs_s3_bucket.bucket.id

  # this is needed if monitoring services without a specific region. Don't need for s3
  include_global_service_events = false

  # enabling this would allow detection of modified log files
  enable_log_file_validation = false
  advanced_event_selector {
    name = "Log PutObject events for landing and data S3 buckets"

    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }

    field_selector {
      field = "eventName"

      equals = [
        "PutObject"
      ]
    }

    field_selector {
      field = "resources.ARN"

      # The trailing slash is intentional; do not exclude it.
      starts_with = [
        "${module.data_s3_bucket.bucket.arn}/",
        "${module.data_landing_s3_bucket.bucket.arn}/"
      ]
    }

    # Remove this if we want to log read events too, like getObject
    field_selector {
      field  = "readOnly"
      equals = ["false"]
    }

    field_selector {
      field  = "resources.type"
      equals = ["AWS::S3::Object"]
    }
  }

  # depends_on = [
  #   data.aws_iam_policy_document.logs_s3_bucket_policy_document
  # ]
}

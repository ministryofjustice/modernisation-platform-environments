# ------------------------------------------------------------------------------
# Serco FMS rotated-key adoption infrastructure
#
# CloudTrail records write-only S3 data events for the three Serco FMS landing
# buckets. The shared logging bucket notifies send_serco_fms_keys whenever a
# CloudTrail event log file is delivered. PR 8 routes those S3 notifications to
# the adoption observer.
# ------------------------------------------------------------------------------

locals {
  serco_fms_key_access_trail_name = format(
    "serco-fms-key-access-%s",
    local.environment_shorthand,
  )

  serco_fms_key_access_trail_log_prefix = (
    "cloudtrail/serco-fms-key-access"
  )

  serco_fms_key_access_trail_arn = format(
    "arn:aws:cloudtrail:%s:%s:trail/%s",
    data.aws_region.current.name,
    data.aws_caller_identity.current.account_id,
    local.serco_fms_key_access_trail_name,
  )

  serco_fms_key_access_log_notification_prefix = format(
    "%s/AWSLogs/%s/CloudTrail/",
    local.serco_fms_key_access_trail_log_prefix,
    data.aws_caller_identity.current.account_id,
  )

  serco_fms_landing_bucket_arns = [
    module.s3-fms-general-landing-bucket.bucket_arn,
    module.s3-fms-ho-landing-bucket.bucket_arn,
    module.s3-fms-specials-landing-bucket.bucket_arn,
  ]
}


# ------------------------------------------------------------------------------
# Capture S3 writes performed with the Serco supplier credentials
#
# The adoption code ignores failed records and accepts activity only after the
# PDF password was released. The trail is restricted to write-only object data
# events for the three FMS landing buckets.
# ------------------------------------------------------------------------------

resource "aws_cloudtrail" "serco_fms_key_access" {
  name = local.serco_fms_key_access_trail_name

  s3_bucket_name = module.s3-logging-bucket.bucket.id
  s3_key_prefix  = local.serco_fms_key_access_trail_log_prefix

  enable_logging = local.serco_fms_key_distribution_enabled

  enable_log_file_validation    = true
  include_global_service_events = false
  is_multi_region_trail         = false

  event_selector {
    read_write_type           = "WriteOnly"
    include_management_events = false

    data_resource {
      type = "AWS::S3::Object"

      values = [
        for bucket_arn in local.serco_fms_landing_bucket_arns :
        "${bucket_arn}/"
      ]
    }
  }

  depends_on = [
    module.s3-logging-bucket,
  ]

  tags = merge(
    local.tags,
    {
      resource-type = "serco-fms-key-distribution"
      purpose       = "serco-fms-key-adoption-observation"
    },
  )
}


# ------------------------------------------------------------------------------
# Allow the logging bucket to invoke the existing distribution Lambda
# ------------------------------------------------------------------------------

resource "aws_lambda_permission" "serco_fms_cloudtrail_logs_s3" {
  statement_id = "AllowExecutionFromS3SercoFmsCloudTrailLogs"

  action = "lambda:InvokeFunction"

  function_name = module.send_serco_fms_keys.lambda_function_name

  principal = "s3.amazonaws.com"

  source_arn = module.s3-logging-bucket.bucket.arn

  source_account = data.aws_caller_identity.current.account_id
}


# ------------------------------------------------------------------------------
# Deliver only CloudTrail event logs, not digest files or unrelated bucket logs
#
# Event logs use:
# <prefix>/AWSLogs/<account>/CloudTrail/<region>/<date>/<file>.json.gz
#
# Digest files use CloudTrail-Digest and are deliberately excluded.
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_notification" "serco_fms_cloudtrail_logs" {
  bucket = module.s3-logging-bucket.bucket.id

  lambda_function {
    id = "serco-fms-key-adoption-observer"

    lambda_function_arn = (
      module.send_serco_fms_keys.lambda_function_arn
    )

    events = [
      "s3:ObjectCreated:*",
    ]

    filter_prefix = (
      local.serco_fms_key_access_log_notification_prefix
    )

    filter_suffix = ".json.gz"
  }

  depends_on = [
    aws_lambda_permission.serco_fms_cloudtrail_logs_s3,
  ]
}
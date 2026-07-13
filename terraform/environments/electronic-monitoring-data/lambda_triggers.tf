module "calculate_checksum_sqs" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-data-bucket.bucket
  lambda_function_name = module.calculate_checksum.lambda_function_name
  bucket_prefix        = local.bucket_prefix
}

resource "aws_s3_bucket_notification" "data_bucket_triggers" {
  bucket = module.s3-data-bucket.bucket.id
  # queue {
  #   queue_arn     = module.calculate_checksum_sqs.sqs_queue.arn
  #   events        = ["s3:ObjectCreated:*"]
  #   filter_suffix = ".zip"
  # }
  # queue {
  #   queue_arn     = module.calculate_checksum_sqs.sqs_queue.arn
  #   events        = ["s3:ObjectCreated:*"]
  #   filter_suffix = ".bak"
  # }
  # queue {
  #   queue_arn     = module.calculate_checksum_sqs.sqs_queue.arn
  #   events        = ["s3:ObjectCreated:*"]
  #   filter_suffix = ".bacpac"
  # }
  # queue {
  #   queue_arn     = module.calculate_checksum_sqs.sqs_queue.arn
  #   events        = ["s3:ObjectCreated:*"]
  #   filter_suffix = ".csv"
  # }
  # queue {
  #   queue_arn     = module.calculate_checksum_sqs.sqs_queue.arn
  #   events        = ["s3:ObjectCreated:*"]
  #   filter_suffix = ".7z"
  # }
  queue {
    queue_arn     = module.copy_mdss_data_sqs.sqs_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".jsonl"
    filter_prefix = "allied/mdss"
  }
  queue {
    queue_arn     = module.process_fms_metadata_sqs.sqs_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".JSON"
    filter_prefix = "serco/fms"
  }
  queue {
    queue_arn     = module.load_historic_csv_sqs.sqs_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".csv"
    filter_prefix = "g4s/lcm"
  }
  queue {
    queue_arn     = module.load_historic_csv_sqs.sqs_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".csv"
    filter_prefix = "scram/alcohol_monitoring"
  }
}

module "process_fms_metadata_sqs" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-data-bucket.bucket
  lambda_function_name = module.fms_expected_file_processor.lambda_function_name
  bucket_prefix        = local.bucket_prefix
}

module "copy_mdss_data_sqs" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-data-bucket.bucket
  lambda_function_name = module.mdss_raw_file_stager.lambda_function_name
  bucket_prefix        = local.bucket_prefix
}

module "virus_scan_file_sqs" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-received-files-bucket.bucket
  lambda_function_name = module.virus_scan_file.lambda_function_name
  bucket_prefix        = local.bucket_prefix
  maximum_concurrency  = 1000
}

module "load_historic_csv_sqs" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-data-bucket.bucket
  lambda_function_name = module.load_historic_csv.lambda_function_name
  bucket_prefix        = local.bucket_prefix
}

resource "aws_s3_bucket_notification" "virus_scan_file" {
  bucket = module.s3-received-files-bucket.bucket.id

  queue {
    queue_arn = module.virus_scan_file_sqs.sqs_queue.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [module.virus_scan_file_sqs]
}


# ----------------------------------------------
# Format Json data sqs queue
# ----------------------------------------------

resource "aws_sqs_queue" "format_fms_json_event_queue" {
  name                       = "format-fms-json-queue"
  visibility_timeout_seconds = 6 * 15 * 60 # 6 x longer than longest possible lambda
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.format_fms_json_event_dlq.arn
    maxReceiveCount     = 5
  })
  sqs_managed_sse_enabled = true
}

resource "aws_sqs_queue" "format_fms_json_event_dlq" {
  name                    = "format-fms-json-dlq"
  sqs_managed_sse_enabled = true
}

data "aws_iam_policy_document" "allow_lambda_to_write" {
  statement {
    sid    = "FormatFMSJsonPermissions"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = [
      "SQS:SendMessage"
    ]
    resources = [
      aws_sqs_queue.format_fms_json_event_queue.arn
    ]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [module.fms_expected_file_processor.lambda_function_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sqs_queue_policy" "allow_lambda_to_write" {
  queue_url = aws_sqs_queue.format_fms_json_event_queue.id
  policy    = data.aws_iam_policy_document.allow_lambda_to_write.json
}


resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.format_fms_json_event_queue.arn
  function_name    = module.fms_raw_file_formatter.lambda_function_name
  batch_size       = 10
  scaling_config {
    maximum_concurrency = 1000
  }
}





module "load_dms_output_event_queue" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-dms-target-store-bucket.bucket
  lambda_function_name = module.load_dms_output.lambda_function_name
  bucket_prefix        = local.bucket_prefix
}

resource "aws_s3_bucket_notification" "load_dms_output_event" {
  bucket = module.s3-dms-target-store-bucket.bucket.id

  queue {
    queue_arn = module.load_dms_output_event_queue.sqs_queue.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [module.load_dms_output_event_queue]
}


# ----------------------------------------------
# Load data sqs queue
# ----------------------------------------------

module "load_mdss_event_queue" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-raw-formatted-data-bucket.bucket
  lambda_function_name = module.load_mdss_lambda.lambda_function_name
  bucket_prefix        = local.bucket_prefix
  maximum_concurrency  = 100
  max_receive_count    = local.load_mdss_sqs_max_receive_count
}

module "load_fms_event_queue" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-raw-formatted-data-bucket.bucket
  lambda_function_name = module.load_fms_lambda.lambda_function_name
  bucket_prefix        = local.bucket_prefix
  maximum_concurrency  = 100
  max_receive_count    = local.load_sqs_max_receive_count
}

module "fms_fan_out_event_queue" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-raw-formatted-data-bucket.bucket
  lambda_function_name = module.fms_validation_rejection_fanout.lambda_function_name
  bucket_prefix        = local.bucket_prefix
  maximum_concurrency  = 100
  max_receive_count    = local.load_sqs_max_receive_count
}

resource "aws_s3_bucket_notification" "load_mdss_event" {
  bucket = module.s3-raw-formatted-data-bucket.bucket.id

  queue {
    queue_arn     = module.load_mdss_event_queue.sqs_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "allied/mdss/"
    filter_suffix = ".jsonl"
  }

  queue {
    queue_arn     = module.load_fms_event_queue.sqs_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "serco/fms"
  }

  queue {
    queue_arn     = module.fms_fan_out_event_queue.sqs_queue.arn
    events        = ["s3:ObjectTagging:Put"]
    filter_prefix = "serco/fms/validation_rejected"
  }

  depends_on = [module.load_mdss_event_queue, module.load_fms_event_queue]
}

# ----------------------------------------------
# Clean up MDSS load queue
# ----------------------------------------------

resource "aws_sqs_queue" "clean_dlt_load_dlq" {
  name                    = "clean-dlt-load-dlq"
  sqs_managed_sse_enabled = true
}

resource "aws_sqs_queue" "clean_dlt_load_queue" {
  name                       = "clean-dlt-load-queue"
  visibility_timeout_seconds = 15 * 60
  message_retention_seconds  = 1209600 # 14 days
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.clean_dlt_load_dlq.arn
    maxReceiveCount     = 5
  })
  sqs_managed_sse_enabled = true
}

# ----------------------------------------------
# MDSS cleanup SQS to Lambda trigger
# ----------------------------------------------

resource "aws_lambda_event_source_mapping" "mdss_cleanup_sqs_trigger" {
  event_source_arn = aws_sqs_queue.clean_dlt_load_queue.arn
  function_name    = module.clean_after_dlt_load.lambda_function_name

  batch_size = 10

  scaling_config {
    maximum_concurrency = 100
  }
}

#-----------------------------------------------------------------------------------
# Schedule MDSS reconciler (every 5 minutes)
#-----------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "mdss_reconciler_schedule" {
  count               = 1
  name                = "mdss_reconciler_schedule"
  description         = "Runs mdss_reconciler on a schedule to backstop missed MDSS loads"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "mdss_reconciler_target" {
  count = 1
  rule  = aws_cloudwatch_event_rule.mdss_reconciler_schedule[0].name
  arn   = module.mdss_load_redrive_controller[0].lambda_function_arn
}

resource "aws_lambda_permission" "mdss_reconciler_allow_eventbridge" {
  count         = 1
  statement_id  = "AllowExecutionFromEventBridgeMdssReconciler"
  action        = "lambda:InvokeFunction"
  function_name = module.mdss_load_redrive_controller[0].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.mdss_reconciler_schedule[0].arn
}

#-----------------------------------------------------------------------------------
# Create p1 exports
#-----------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "schedule_p1_creation" {
  name        = "create-p1-export"
  description = "Trigger the creation of P1 data export."

  schedule_expression = "cron(0 7 * * ? *)"
}

resource "aws_cloudwatch_event_target" "schedule_p1_creation_target" {
  rule = aws_cloudwatch_event_rule.schedule_p1_creation.name
  arn  = aws_sqs_queue.p1_creation_queue.arn
}

resource "aws_sqs_queue" "p1_creation_queue_dlq" {
  name                    = "p1-creation-queue-dlq"
  sqs_managed_sse_enabled = true
}

resource "aws_sqs_queue" "p1_creation_queue" {
  name                       = "p1-creation-queue"
  visibility_timeout_seconds = 15 * 60
  message_retention_seconds  = 1209600 # 14 days
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.p1_creation_queue_dlq.arn
    maxReceiveCount     = 2
  })
  sqs_managed_sse_enabled = true
}

data "aws_iam_policy_document" "p1_create_export" {
  statement {
    sid    = "SendMessagesToTriggerP1Export"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.p1_creation_queue.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.schedule_p1_creation.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "p1_creation_policy" {
  queue_url = aws_sqs_queue.p1_creation_queue.id
  policy    = data.aws_iam_policy_document.p1_create_export.json
}


resource "aws_lambda_event_source_mapping" "p1_creation_trigger" {
  event_source_arn = aws_sqs_queue.p1_creation_queue.arn
  function_name    = module.create_p1_export.lambda_function_name

  batch_size = 2

  scaling_config {
    maximum_concurrency = 2
  }
}


#-----------------------------------------------------------------------------------
# Schedule merge load lambda
#-----------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "merge_load_schedule" {
  count               = 1
  name                = "merge_load_schedule"
  description         = "Runs merge_load Lambdas for MDSS tables on a schedule"
  schedule_expression = "rate(3 minutes)"
}

# target mdss_staged_event
resource "aws_cloudwatch_event_target" "merge_mdss_staged_event" {
  count = 1
  rule  = aws_cloudwatch_event_rule.merge_load_schedule[0].name
  arn   = module.merge_mdss_staged_event[0].lambda_function_arn
}

resource "aws_lambda_permission" "allow_eventbridge_merge_mdss_staged_event" {
  count         = 1
  statement_id  = "AllowExecutionFromEventBridgeStagedMdssStaged"
  action        = "lambda:InvokeFunction"
  function_name = module.merge_mdss_staged_event[0].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.merge_load_schedule[0].arn
}

# target mdss_staged_position
resource "aws_cloudwatch_event_target" "merge_mdss_staged_position" {
  count = 1
  rule  = aws_cloudwatch_event_rule.merge_load_schedule[0].name
  arn   = module.merge_mdss_staged_position[0].lambda_function_arn
}

resource "aws_lambda_permission" "allow_eventbridge_merge_mdss_staged_position" {
  count         = 1
  statement_id  = "AllowExecutionFromEventBridgeStagedMdssStaged"
  action        = "lambda:InvokeFunction"
  function_name = module.merge_mdss_staged_position[0].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.merge_load_schedule[0].arn
}

# target merge_ac_position
resource "aws_cloudwatch_event_target" "merge_ac_position" {
  count = 1
  rule  = aws_cloudwatch_event_rule.merge_load_schedule[0].name
  arn   = module.merge_ac_position[0].lambda_function_arn
}

resource "aws_lambda_permission" "allow_eventbridge_acquisitive_crime_position" {
  count         = local.is-development ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridgeAcquisitiveCrimePosition"
  action        = "lambda:InvokeFunction"
  function_name = module.merge_ac_position[0].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.merge_load_schedule[0].arn
}

# target merge_emdi_position
resource "aws_cloudwatch_event_target" "merge_emdi_position" {
  count = 1
  rule  = aws_cloudwatch_event_rule.merge_load_schedule[0].name
  arn   = module.merge_emdi_position[0].lambda_function_arn
}

resource "aws_lambda_permission" "allow_eventbridge_emdi_position" {
  count         = 1
  statement_id  = "AllowExecutionFromEventBridgeEmdiPosition"
  action        = "lambda:InvokeFunction"
  function_name = module.merge_emdi_position[0].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.merge_load_schedule[0].arn
}

# --------------------------------------------------------
# update_p1_export
# --------------------------------------------------------

resource "aws_lambda_permission" "update_p1_export_api_gw" {
  count         = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  statement_id  = "AllowAPIGatewayInvokeUpdateP1Export"
  action        = "lambda:InvokeFunction"
  function_name = module.update_p1_export[0].lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.update_p1_export[0].execution_arn}/*/*"
}

# ------------------------------------------------------------------------------
# Serco FMS Scheduler execution role
# ------------------------------------------------------------------------------

resource "aws_iam_role" "send_serco_fms_keys_scheduler" {
  name = format(
    "send_serco_fms_keys_scheduler_role_%s",
    local.environment_shorthand,
  )

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "scheduler.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy" "send_serco_fms_keys_scheduler" {
  name = "send_serco_fms_keys_scheduler_invoke_policy"

  role = aws_iam_role.send_serco_fms_keys_scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "lambda:InvokeFunction",
        ]

        Resource = [
          module.send_serco_fms_keys.lambda_function_arn,
        ]
      },
    ]
  })
}


# ------------------------------------------------------------------------------
# Quarterly encrypted-key distribution
# ------------------------------------------------------------------------------

resource "aws_scheduler_schedule" "send_serco_fms_keys" {
  name = format(
    "send_serco_fms_keys_quarterly_%s",
    local.environment_shorthand,
  )

  description = "Sends encrypted Serco FMS keys after quarterly rotation"

  state = (
    local.serco_fms_key_distribution_enabled
    ? "ENABLED"
    : "DISABLED"
  )

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(30 12 ? FEB,MAY,AUG,NOV TUE#2 *)"

  schedule_expression_timezone = "Europe/London"

  target {
    arn = module.send_serco_fms_keys.lambda_function_arn

    role_arn = aws_iam_role.send_serco_fms_keys_scheduler.arn

    input = jsonencode({
      source = "quarterly-schedule"
      mode   = "send"
    })
  }
}


# ------------------------------------------------------------------------------
# Daily handover watchdog
# ------------------------------------------------------------------------------

resource "aws_scheduler_schedule" "send_serco_fms_keys_watchdog" {
  name = format(
    "send_serco_fms_keys_watchdog_%s",
    local.environment_shorthand,
  )

  description = "Checks active Serco FMS handovers for overdue stages"

  state = (
    local.serco_fms_key_distribution_enabled
    ? "ENABLED"
    : "DISABLED"
  )

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 14 * * ? *)"

  schedule_expression_timezone = "Europe/London"

  target {
    arn = module.send_serco_fms_keys.lambda_function_arn

    role_arn = aws_iam_role.send_serco_fms_keys_scheduler.arn

    input = jsonencode({
      source = "daily-watchdog"
      mode   = "check_state"
    })
  }
}


# ------------------------------------------------------------------------------
# CloudTrail S3 write data events
#
# The trail captures write operations against the three supplier landing
# buckets. EventBridge routes completed object uploads to the observer.
# ------------------------------------------------------------------------------

resource "aws_cloudtrail" "serco_fms_key_access" {
  name = local.serco_fms_key_access_trail_name

  s3_bucket_name = module.s3-logging-bucket.bucket.id

  s3_key_prefix = local.serco_fms_key_access_trail_log_prefix

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
      purpose = "serco-fms-key-access-observation"
    },
  )
}


# ------------------------------------------------------------------------------
# Successful supplier S3 uploads -> key-access observer
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "serco_fms_key_access" {
  name = format(
    "serco-fms-key-access-%s",
    local.environment_shorthand,
  )

  description = (
    "Routes successful FMS supplier uploads to the key access observer"
  )

  state = (
    local.serco_fms_key_distribution_enabled
    ? "ENABLED"
    : "DISABLED"
  )

  event_pattern = jsonencode({
    source = [
      "aws.s3",
    ]

    detail-type = [
      "AWS API Call via CloudTrail",
    ]

    detail = {
      eventSource = [
        "s3.amazonaws.com",
      ]

      eventName = [
        "PutObject",
        "CompleteMultipartUpload",
      ]

      requestParameters = {
        bucketName = local.serco_fms_landing_bucket_ids
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "serco_fms_key_access" {
  rule = aws_cloudwatch_event_rule.serco_fms_key_access.name

  target_id = "serco-fms-key-access-observer"

  arn = (
    module.serco_fms_key_access_observer.lambda_function_arn
  )
}

resource "aws_lambda_permission" "serco_fms_key_access_eventbridge" {
  statement_id = "AllowExecutionFromEventBridgeSercoFmsKeyAccess"

  action = "lambda:InvokeFunction"

  function_name = (
    module.serco_fms_key_access_observer.lambda_function_name
  )

  principal = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.serco_fms_key_access.arn
}
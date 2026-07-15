# ------------------------------------------
# Unzip Files
# ------------------------------------------

data "aws_iam_policy_document" "trigger_unzip_lambda" {
  statement {
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]
    resources = [
      module.unzip_single_file.lambda_function_arn,
      module.unzipped_presigned_url.lambda_function_arn
    ]
  }
}

resource "aws_iam_policy" "trigger_unzip_lambda" {
  name   = "trigger_unzip_lambda"
  policy = data.aws_iam_policy_document.trigger_unzip_lambda.json
}

# ------------------------------------------
# DMS Validation
# ------------------------------------------

data "aws_iam_policy_document" "dms_validation_step_function_policy_document" {
  count = local.is-development || local.is-production || local.is-preproduction ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]
    resources = [
      module.dms_retrieve_metadata[0].lambda_function_arn,
    module.dms_validation[0].lambda_function_arn]
  }
}

resource "aws_iam_policy" "dms_validation_step_function_policy" {
  count = local.is-development || local.is-production || local.is-preproduction ? 1 : 0

  name   = "dms_validation_step_function_role"
  policy = data.aws_iam_policy_document.dms_validation_step_function_policy_document[0].json
}


# ------------------------------------------
# Data Cut Back
# ------------------------------------------

data "aws_iam_policy_document" "data_cutback_policy_document" {
  count = local.is-development || local.is-production ? 1 : 0
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [module.data_cutback[0].lambda_function_arn]
  }
}

resource "aws_iam_policy" "data_cutback_step_function_policy" {
  count = local.is-development || local.is-production ? 1 : 0

  name   = "data_cutback_step_function_role"
  policy = data.aws_iam_policy_document.data_cutback_policy_document[0].json
}


# ------------------------------------------
# Ears and Sars
# ------------------------------------------

data "aws_iam_policy_document" "ears_sars_policy_document" {
  count = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [module.ears_sars_request[0].lambda_function_arn, module.write_to_sharepoint[0].lambda_function_arn, ]
  }
}

resource "aws_iam_policy" "ears_sars_step_function_policy" {
  count  = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  name   = "ears_sars_step_function_role"
  policy = data.aws_iam_policy_document.ears_sars_policy_document[0].json
}

# ------------------------------------------
# GDPR
# ------------------------------------------

data "aws_iam_policy_document" "gdpr_delete_policy_document" {
  count = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "ecs:RunTask"
    ]
    resources = [
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/${aws_ecs_task_definition.emds-gdpr-structured-data-deletion[0].family}:*",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/${aws_ecs_task_definition.emds-gdpr-iceberg-table-maintenance[0].family}:*"
    ]
  }

  statement {
    sid       = "BatchDescribeJobsGlobal"
    effect    = "Allow"
    actions   = ["batch:DescribeJobs"]
    resources = ["*"]
  }

  statement {
    sid     = "BatchSubmitJobScoped"
    effect  = "Allow"
    actions = ["batch:SubmitJob"]

    resources = [
      aws_batch_job_queue.shred_unstructured_from_zip_batch_queue[0].arn,
      "${aws_batch_job_definition.shred_unstructured_from_zip_job.arn}:*",
      "arn:aws:batch:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:job/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "batch:SubmitJob",
      "batch:DescribeJobs",
      "batch:TerminateJob"
    ]
    resources = ["arn:aws:batch:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:job-definition/shred-unstructured-from-zip-job:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [module.gdpr_unstructured_control_lambda[0].lambda_function_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.ecs_execution_role.arn,
      aws_iam_role.ecs_gdpr_execution_role.arn,
      aws_iam_role.gdpr_structured_job_role[0].arn
    ]
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "events:PutTargets",
      "events:PutRule",
      "events:DescribeRule"
    ]
    resources = [
      "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForECSTaskRule",
      "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForBatchJobsRule"
    ]
  }
  statement {
    sid    = "PublishGdprStepFunctionNotifications"
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      aws_sns_topic.emds_alerts.arn
    ]
  }

  statement {
    sid    = "UseEncryptedAlertsTopicForGdprStepFunction"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]
    resources = [
      aws_kms_key.emds_alerts.arn
    ]
  }
}

resource "aws_iam_policy" "gdpr_delete_iam_policy" {
  count  = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  name   = "gdpr_deletion_step_function_role"
  policy = data.aws_iam_policy_document.gdpr_delete_policy_document[0].json
}

# ------------------------------------------------------------------------------
# Staging DB janitor Step Function
# ------------------------------------------------------------------------------

data "aws_iam_policy_document" "staging_db_janitor_sfn_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "staging_db_janitor_state_machine" {
  name = "staging_db_janitor_state_machine_role"

  assume_role_policy = (
    data.aws_iam_policy_document.staging_db_janitor_sfn_assume.json
  )
}

resource "aws_iam_role_policy" "staging_db_janitor_state_machine_invoke" {
  name = "staging_db_janitor_state_machine_invoke_policy"
  role = aws_iam_role.staging_db_janitor_state_machine.id

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "AllowInvokeStagingDbJanitorLambda"
          Effect = "Allow"
          Action = [
            "lambda:InvokeFunction"
          ]
          Resource = [
            module.staging_db_janitor.lambda_function_arn
          ]
        }
      ]
    }
  )
}

# ------------------------------------------------------------------------------
# Landing DLQ redriver Step Function
# ------------------------------------------------------------------------------

data "aws_iam_policy_document" "landing_dlq_redriver_sfn_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "landing_dlq_redriver_state_machine" {
  name               = "landing_dlq_redriver_state_machine_role"
  assume_role_policy = data.aws_iam_policy_document.landing_dlq_redriver_sfn_assume.json
}

resource "aws_iam_role_policy" "landing_dlq_redriver_state_machine_invoke" {
  name = "landing_dlq_redriver_state_machine_invoke_policy"
  role = aws_iam_role.landing_dlq_redriver_state_machine.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowInvokeLandingDlqRedriverLambda"
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
        ]
        Resource = [
          module.landing_file_dlq_redriver.lambda_function_arn,
        ]
      }
    ]
  })
}

data "aws_iam_policy_document" "landing_dlq_redriver_eventbridge_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "landing_dlq_redriver_eventbridge" {
  name               = "landing_dlq_redriver_eventbridge_role"
  assume_role_policy = data.aws_iam_policy_document.landing_dlq_redriver_eventbridge_assume.json
}

resource "aws_iam_role_policy" "landing_dlq_redriver_eventbridge_start" {
  name = "landing_dlq_redriver_eventbridge_start_policy"
  role = aws_iam_role.landing_dlq_redriver_eventbridge.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowStartLandingDlqRedriverWorkflow"
        Effect = "Allow"
        Action = [
          "states:StartExecution",
        ]
        Resource = [
          aws_sfn_state_machine.landing_dlq_redriver.arn,
        ]
      }
    ]
  })
}

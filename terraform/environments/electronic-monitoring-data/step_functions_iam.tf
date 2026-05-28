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
  count = local.is-development || local.is-preproduction ? 1 : 0
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [module.ears_sars_request[0].lambda_function_arn]
  }
}

resource "aws_iam_policy" "ears_sars_step_function_policy" {
  count  = local.is-development || local.is-preproduction ? 1 : 0
  name   = "ears_sars_step_function_role"
  policy = data.aws_iam_policy_document.ears_sars_policy_document[0].json
}

# ------------------------------------------
# GDPR 
# ------------------------------------------

data "aws_iam_policy_document" "gdpr_delete_policy_document" {
  count = local.is-development || local.is-preproduction ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "ecs:RunTask"
    ]
    resources = [
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/${aws_ecs_task_definition.emds-gdpr-structured-data-deletion[0].family}:*"
    ]
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
    resources = ["arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForECSTaskRule"]
  }
}

resource "aws_iam_policy" "gdpr_delete_iam_policy" {
  count  = local.is-development || local.is-preproduction ? 1 : 0
  name   = "gdpr_deletion_step_function_role"
  policy = data.aws_iam_policy_document.gdpr_delete_policy_document[0].json
}

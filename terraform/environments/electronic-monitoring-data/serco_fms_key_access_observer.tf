resource "aws_iam_role" "serco_fms_key_access_observer" {
  name               = "serco_fms_key_access_observer_${local.environment_shorthand}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "serco_fms_key_access_observer" {
  statement {
    sid    = "ListDistributionState"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      module.s3-serco-fms-key-distribution-bucket.bucket.arn,
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        "${local.serco_fms_key_distribution_state_prefix}/${local.environment_shorthand}",
        "${local.serco_fms_key_distribution_state_prefix}/${local.environment_shorthand}/*",
      ]
    }
  }

  statement {
    sid    = "ReadWriteDistributionState"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = [
      "${module.s3-serco-fms-key-distribution-bucket.bucket.arn}/${local.serco_fms_key_distribution_state_prefix}/${local.environment_shorthand}/*",
    ]
  }

  statement {
    sid    = "PublishAccessObservedNotifications"
    effect = "Allow"

    actions = [
      "sns:Publish",
    ]

    resources = [
      aws_sns_topic.emds_alerts.arn,
    ]
  }
}

resource "aws_iam_policy" "serco_fms_key_access_observer" {
  name   = "serco_fms_key_access_observer_${local.environment_shorthand}"
  policy = data.aws_iam_policy_document.serco_fms_key_access_observer.json
}

resource "aws_iam_role_policy_attachment" "serco_fms_key_access_observer" {
  role       = aws_iam_role.serco_fms_key_access_observer.name
  policy_arn = aws_iam_policy.serco_fms_key_access_observer.arn
}

module "serco_fms_key_access_observer" {
  source                         = "./modules/lambdas"
  is_image                       = true
  function_name                  = "serco_fms_key_access_observer"
  role_name                      = aws_iam_role.serco_fms_key_access_observer.name
  role_arn                       = aws_iam_role.serco_fms_key_access_observer.arn
  handler                        = "serco_fms_key_access_observer.handler"
  memory_size                    = 256
  timeout                        = 60
  reserved_concurrent_executions = 2
  core_shared_services_id        = local.environment_management.account_ids["core-shared-services-production"]
  production_dev                 = local.is-production ? "prod" : local.is-preproduction ? "preprod" : local.is-test ? "test" : "dev"

  environment_variables = {
    ENVIRONMENT = local.environment_shorthand

    STATE_BUCKET = (
      module.s3-serco-fms-key-distribution-bucket.bucket.id
    )

    STATE_PREFIX = local.serco_fms_key_distribution_state_prefix

    STATE_SCAN_LIMIT = "25"

    SNS_TOPIC_ARN = aws_sns_topic.emds_alerts.arn
  }
}

resource "aws_cloudwatch_event_rule" "serco_fms_key_access_observed" {
  name = "serco-fms-key-access-observed-${local.environment_shorthand}"

  description = "Detects Serco FMS S3 access after key handover"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["s3.amazonaws.com"]
      eventName = [
        "PutObject",
        "CompleteMultipartUpload",
        "CreateMultipartUpload",
        "ListBucket",
        "GetBucketLocation",
      ]
      requestParameters = {
        bucketName = [
          module.s3-fms-general-landing-bucket.bucket_id,
          module.s3-fms-ho-landing-bucket.bucket_id,
          module.s3-fms-specials-landing-bucket.bucket_id,
        ]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "serco_fms_key_access_observed" {
  rule = aws_cloudwatch_event_rule.serco_fms_key_access_observed.name
  arn  = module.serco_fms_key_access_observer.lambda_function_arn
}

resource "aws_lambda_permission" "serco_fms_key_access_observed" {
  statement_id  = "AllowExecutionFromEventBridgeSercoFmsAccessObserved"
  action        = "lambda:InvokeFunction"
  function_name = module.serco_fms_key_access_observer.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.serco_fms_key_access_observed.arn
}
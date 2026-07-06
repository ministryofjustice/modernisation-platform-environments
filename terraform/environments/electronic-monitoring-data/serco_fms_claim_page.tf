resource "aws_iam_role" "serco_fms_claim_page" {
  name               = "serco_fms_claim_page_lambda_role_${local.environment_shorthand}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "serco_fms_claim_page" {
  statement {
    sid    = "ReadDistributionAllowlist"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]

    resources = [
      "${module.s3-serco-fms-key-distribution-bucket.bucket.arn}/${local.serco_fms_key_distribution_allowlist_key}",
    ]
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
    sid    = "ReadEncryptedDistributionFiles"
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${module.s3-serco-fms-key-distribution-bucket.bucket.arn}/${local.serco_fms_key_distribution_files_prefix}/${local.environment_shorthand}/*",
    ]
  }
  statement {
    sid    = "PublishClaimNotifications"
    effect = "Allow"

    actions = [
      "sns:Publish",
    ]

    resources = [
      aws_sns_topic.emds_alerts.arn,
    ]
  }  
}

resource "aws_iam_policy" "serco_fms_claim_page" {
  name   = "serco_fms_claim_page_lambda_policy_${local.environment_shorthand}"
  policy = data.aws_iam_policy_document.serco_fms_claim_page.json
}

resource "aws_iam_role_policy_attachment" "serco_fms_claim_page" {
  role       = aws_iam_role.serco_fms_claim_page.name
  policy_arn = aws_iam_policy.serco_fms_claim_page.arn
}

module "serco_fms_claim_page" {
  source                         = "./modules/lambdas"
  is_image                       = true
  function_name                  = "serco_fms_claim_page"
  role_name                      = aws_iam_role.serco_fms_claim_page.name
  role_arn                       = aws_iam_role.serco_fms_claim_page.arn
  handler                        = "serco_fms_claim_page.handler"
  memory_size                    = 256
  timeout                        = 30
  reserved_concurrent_executions = 2
  core_shared_services_id        = local.environment_management.account_ids["core-shared-services-production"]
  production_dev                 = local.is-production ? "prod" : local.is-preproduction ? "preprod" : local.is-test ? "test" : "dev"

  environment_variables = {
    ENVIRONMENT = local.environment_shorthand

    STATE_BUCKET = (
      module.s3-serco-fms-key-distribution-bucket.bucket.id
    )

    STATE_PREFIX = local.serco_fms_key_distribution_state_prefix

    ALLOWLIST_BUCKET = (
      module.s3-serco-fms-key-distribution-bucket.bucket.id
    )

    ALLOWLIST_KEY = local.serco_fms_key_distribution_allowlist_key

    FILE_URL_TTL_SECONDS = "900"
    
    SNS_TOPIC_ARN = aws_sns_topic.emds_alerts.arn    
  }
}

resource "aws_lambda_function_url" "serco_fms_claim_page" {
  function_name      = module.serco_fms_claim_page.lambda_function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_methods = [
      "GET",
      "POST",
    ]
    allow_origins = [
      "*",
    ]
    max_age = 0
  }
}
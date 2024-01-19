module "jml_extract" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 6.0"

  publish        = true
  create_package = false

  function_name = "data_platform_jml_extract"
  description   = "Generates a JML report and sends it to JMLv4"
  package_type  = "Image"
  image_uri     = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-jml-extract-lambda-ecr-repo:1.0.1"

  environment_variables = {
    SECRET_ID       = data.aws_secretsmanager_secret_version.govuk_notify_api_key.secret_string
    LOG_GROUP_NAMES = "CHANGEME"
    EMAIL_SECRET    = data.aws_secretsmanager_secret_version.email_secret.secret_string
    TEMPLATE_ID     = "CHANGEME"
  }

  attach_policy_statements = true
  policy_statements = {
    "cloudwatch" = {
      sid    = "CloudWatch"
      effect = "Allow"
      actions = [
        "cloudwatch:GenerateQuery",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups",
        "logs:GetLogEvents"
      ]
      resources = [
        "arn:aws:logs:eu-west-2:096705367497:log-group:/aws/events/auth0/*"
      ]
    }
    "secretsmanager" = {
      sid    = "SecretsManager"
      effect = "Allow"
      actions = [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:ListSecrets"
      ]
      resources = [
        "arn:aws:secretsmanager:eu-west-2:096705367497:secret:gov-uk-notify/production/api-key-WSSdUR",
        "arn:aws:secretsmanager:eu-west-2:096705367497:secret:jml/email-uQGTzR" #api-key value manually added
      ]
    }
  }

  allowed_triggers = {
    "eventbridge" = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.jml_lambda_trigger.arn
    }
  }
}

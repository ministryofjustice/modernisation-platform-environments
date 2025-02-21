## EventBridge

# alpha-analytics-moj

module "alpha-analytics-moj" {
  source = "./modules/eventbridge"

  event_source = "aws.partner/auth0.com/alpha-analytics-moj-9790e567-420a-48b2-b978-688dd998d26c/auth0.logs"
  log_group_arn = aws_cloudwatch_log_group.auth0_log_group.arn
}

# justice-cloud-platform

module "justice-cloud-platform" {
  source = "./modules/eventbridge"

  event_source = "aws.partner/auth0.com/justice-cloud-platform-9bea4c89-7006-4060-94f8-ef7ed853d946/auth0.logs"
  log_group_arn = aws_cloudwatch_log_group.auth0_log_group.arn
}

# ministryofjustice

module "ministryofjustice" {
  source = "./modules/eventbridge"

  event_source = "aws.partner/auth0.com/ministryofjustice-775267e6-72e7-46a5-9059-a396cd0625e7/auth0.logs"
  log_group_arn = aws_cloudwatch_log_group.auth0_log_group.arn
}

# operations-engineering

module "operations-engineering" {
  source = "./modules/eventbridge"

  event_source = "aws.partner/auth0.com/operations-engineering-4d9a5624-861c-4871-981e-fce33be08149/auth0.logs"
  log_group_arn = aws_cloudwatch_log_group.auth0_log_group.arn
}

## CloudWatch

resource "aws_cloudwatch_log_group" "auth0_log_group" {
  name              = "/aws/events/LogsFromOperationsEngineeringAuth0"
  retention_in_days = 90
}

## IAM

resource "aws_iam_role" "github_dormant_users_role" {
  name               = "github-dormant-users"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role_policy_document.json
}

resource "aws_iam_role_policy_attachment" "github_dormant_users_s3_full_access_attachment" {
  role       = aws_iam_role.github_dormant_users_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "github_dormant_users_cloudwatch_logs_full_access_attachment" {
  role       = aws_iam_role.github_dormant_users_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "github_dormant_users_cloudwatch_app_insights_full_access_attachment" {
  role       = aws_iam_role.github_dormant_users_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchApplicationInsightsFullAccess"
}
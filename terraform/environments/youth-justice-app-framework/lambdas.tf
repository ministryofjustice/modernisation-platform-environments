###Update DC Names so auth can properly use ldaps
module "update-dc-names" {
  source           = "../../modules/lambda"
  account_number   = var.account_number
  project_name     = var.project_name
  tags             = var.tags
  region           = var.region
  lambda_s3_bucket = var.lambda_s3_bucket
  environment      = var.environment
  lambda_role      = var.lambda_role
  lambda           = local.update-dc-names
}

#every 15 mins
resource "aws_cloudwatch_event_rule" "update-dc-names" {
  name                = "update-dc-names"
  description         = "update-dc-names"
  schedule_expression = "rate(15 minutes)"
  tags                = local.tags
}

resource "aws_cloudwatch_event_target" "update-dc-names" {
  target_id = "update-dc-names"
  rule      = aws_cloudwatch_event_rule.update-dc-names.name
  arn       = aws_lambda_function.start_aurora_lambda_function.arn
}

resource "aws_lambda_permission" "update-dc-names" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.update-dc-names.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.update-dc-names.arn
}

###Canary testing for yjaf
module "serverlessrepo-lambda-canary" {
  source           = "../../modules/lambda"
  account_number   = var.account_number
  project_name     = var.project_name
  tags             = var.tags
  region           = var.region
  lambda_s3_bucket = var.lambda_s3_bucket
  environment      = var.environment
  lambda_role      = var.lambda_role
  lambda           = local.serverlessrepo-lambda-canary
}

#every 15 mins
resource "aws_cloudwatch_event_rule" "serverlessrepo-lambda-canary" {
  name                = "serverlessrepo-lambda-canary"
  description         = "serverlessrepo-lambda-canary"
  schedule_expression = "rate(15 minutes)"
  tags                = local.tags
}

resource "aws_cloudwatch_event_target" "serverlessrepo-lambda-canary" {
  target_id = "serverlessrepo-lambda-canary"
  rule      = aws_cloudwatch_event_rule.serverlessrepo-lambda-canary.name
  arn       = aws_lambda_function.start_aurora_lambda_function.arn
}

resource "aws_lambda_permission" "serverlessrepo-lambda-canary" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.serverlessrepo-lambda-canary.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.serverlessrepo-lambda-canary.arn
}


###s3 replication lambda
module "s3-cross-account-replication" {
  source           = "../../modules/lambda"
  account_number   = var.account_number
  project_name     = var.project_name
  tags             = var.tags
  region           = var.region
  lambda_s3_bucket = var.lambda_s3_bucket
  environment      = var.environment
  lambda_role      = var.lambda_role
  lambda           = local.s3-cross-account-replication
}

#every 15 mins
resource "aws_cloudwatch_event_rule" "s3-cross-account-replication" {
  name                = "s3-cross-account-replication"
  description         = "s3-cross-account-replication"
  schedule_expression = "rate(15 minutes)"
  tags                = local.tags
}

resource "aws_cloudwatch_event_target" "s3-cross-account-replication" {
  target_id = "s3-cross-account-replication"
  rule      = aws_cloudwatch_event_rule.s3-cross-account-replication.name
  arn       = aws_lambda_function.start_aurora_lambda_function.arn
}

resource "aws_lambda_permission" "s3-cross-account-replication" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.s3-cross-account-replication.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3-cross-account-replication.arn
}
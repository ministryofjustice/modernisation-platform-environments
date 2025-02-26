###Update DC Names so auth can properly use ldaps
module "update-dc-names" {
  source         = "./modules/lambda"
  account_number = local.environment_management.account_ids[terraform.workspace]
  project_name   = local.project_name
  tags           = local.tags
  region         = data.aws_region.current.name
  environment    = local.environment
  lambda_role    = local.update-dc-names-role
  lambda         = local.update-dc-names
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
  arn       = module.update-dc-names.lambda_arn
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
  source         = "./modules/lambda"
  account_number = local.environment_management.account_ids[terraform.workspace]
  project_name   = local.project_name
  tags           = local.tags
  region         = data.aws_region.current.name
  environment    = local.environment
  lambda_role    = local.serverlessrepo-lambda-canary-role
  lambda         = local.serverlessrepo-lambda-canary
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
  arn       = module.serverlessrepo-lambda-canary.lambda_arn
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
  source         = "./modules/lambda"
  account_number = local.environment_management.account_ids[terraform.workspace]
  project_name   = local.project_name
  tags           = local.tags
  region         = data.aws_region.current.name
  environment    = local.environment
  lambda_role    = local.s3-cross-account-replication-role
  lambda         = local.s3-cross-account-replication
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
  arn       = module.s3-cross-account-replication.lambda_arn
}

resource "aws_lambda_permission" "s3-cross-account-replication" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.s3-cross-account-replication.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3-cross-account-replication.arn
}

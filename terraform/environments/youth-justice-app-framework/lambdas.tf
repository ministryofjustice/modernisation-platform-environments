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

resource "aws_iam_role_policy_attachment" "lambda_iam_roles_basic_policy" {
  role       = local.update-dc-names-role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
  depends_on = [module.update-dc-names]
}

###Canary testing for yjaf
module "serverlessrepo-lambda-canary-sg" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"

  name        = "serverlessrepo-lambda-canary-sg"
  description = "ALB security group"
  vpc_id      = data.aws_vpc.shared.id

  egress_with_source_security_group_id = [
    {
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "TCP"
      description              = "Egress to YJAF Services"
      source_security_group_id = module.internal_alb.alb_security_group_id
    }
  ]

  tags = local.tags
}

module "serverlessrepo-lambda-canary" {
  source                          = "./modules/lambda"
  account_number                  = local.environment_management.account_ids[terraform.workspace]
  project_name                    = local.project_name
  tags                            = local.tags
  region                          = data.aws_region.current.name
  environment                     = local.environment
  lambda_role                     = local.serverlessrepo-lambda-canary-role
  lambda                          = local.serverlessrepo-lambda-canary
  cloudwatch_log_group_kms_key_id = module.kms.key_arn
}

#ESB to Int load balancer
resource "aws_security_group_rule" "allow_alb_from_canary" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = module.internal_alb.alb_security_group_id
  source_security_group_id = module.serverlessrepo-lambda-canary-sg.security_group_id
  description              = "Lambda to YJAF Internal ALB"
}

resource "aws_cloudwatch_log_subscription_filter" "healthcheck" {
  name            = "firehose-subscription"
  log_group_name  = module.serverlessrepo-lambda-canary.log_group_name
  filter_pattern  = ""
  destination_arn = module.datadog.aws_kinesis_firehose_delivery_stream_arn
  role_arn        = module.datadog.datadog_firehose_iam_role_arn
}

#every 15 mins
resource "aws_cloudwatch_event_rule" "serverlessrepo-lambda-canary" {
  name                = "serverlessrepo-lambda-canary"
  description         = "serverlessrepo-lambda-canary"
  schedule_expression = "rate(1 minute)"
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
  schedule_expression = "rate(5 minutes)"
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

resource "aws_lambda_permission" "s3-cross-account-replication-s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = module.s3-cross-account-replication.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = local.s3-cross-account-replication-s3-arn
}

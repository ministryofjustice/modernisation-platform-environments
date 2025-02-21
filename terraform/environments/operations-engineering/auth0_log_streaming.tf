locals {
  event_sources = {
    alpha-analytics-moj    = "aws.partner/auth0.com/alpha-analytics-moj-9790e567-420a-48b2-b978-688dd998d26c/auth0.logs"
    justice-cloud-platform = "aws.partner/auth0.com/justice-cloud-platform-9bea4c89-7006-4060-94f8-ef7ed853d946/auth0.logs"
    ministryofjustice    = "aws.partner/auth0.com/ministryofjustice-775267e6-72e7-46a5-9059-a396cd0625e7/auth0.logs"
    operations-engineering = "aws.partner/auth0.com/operations-engineering-4d9a5624-861c-4871-981e-fce33be08149/auth0.logs"
  }
}

## EventBridge

# alpha-analytics-moj

import {
  to = module.eventbridge_modules["alpha-analytics-moj"].aws_cloudwatch_event_bus.this
  id = "aws.partner/auth0.com/alpha-analytics-moj-9790e567-420a-48b2-b978-688dd998d26c/auth0.logs"
}

import {
  to = module.eventbridge_modules["justice-cloud-platform"].aws_cloudwatch_event_bus.this
  id = "aws.partner/auth0.com/justice-cloud-platform-9bea4c89-7006-4060-94f8-ef7ed853d946/auth0.logs"
}

import {
  to = module.eventbridge_modules["ministryofjustice"].aws_cloudwatch_event_bus.this
  id = "aws.partner/auth0.com/ministryofjustice-775267e6-72e7-46a5-9059-a396cd0625e7/auth0.logs"
}

import {
  to = module.eventbridge_modules["operations-engineering"].aws_cloudwatch_event_bus.this
  id = "aws.partner/auth0.com/operations-engineering-4d9a5624-861c-4871-981e-fce33be08149/auth0.logs"
}

module "eventbridge_modules" {
  for_each = local.event_sources

  source         = "./modules/eventbridge"
  event_source   = each.value
  log_group_arn  = aws_cloudwatch_log_group.auth0_log_group.arn
}

## CloudWatch

import {
  to = aws_cloudwatch_log_group.auth0_log_group
  id = "/aws/events/LogsFromOperationsEngineeringAuth0"
}

data "aws_iam_policy_document" "auth0_log_group_key" {

  # checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  # checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # checkov:skip=CKV_AWS_356: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions"

  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    actions = ["kms:*"]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
  }

  statement {
    sid    = "Allow Dormant Users role to use KMS key on Auth0 log group"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:Describe",
      "kms:GenerateDataKey*"
    ]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.github_dormant_users_role.arn
      ]
    }
    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values = [ "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-dormant-users" ]
    }
  }
}

resource "aws_kms_key" "auth0_log_group_key" {
  description         = "KMS key to encrypt auth0 cloudwatch log group"
  policy              = data.aws_iam_policy_document.auth0_log_group_key.json
  enable_key_rotation = true
}

resource "aws_cloudwatch_log_group" "auth0_log_group" {
  name              = "/aws/events/LogsFromOperationsEngineeringAuth0"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.auth0_log_group_key.arn

  depends_on = [ aws_kms_key.auth0_log_group_key ]
}

## IAM

import {
  id = "github-dormant-users"
  to = aws_iam_role.github_dormant_users_role
}

import {
  id = "github-dormant-users/arn:aws:iam::aws:policy/AmazonS3FullAccess"
  to = aws_iam_role_policy_attachment.github_dormant_users_s3_full_access_attachment
}

import {
  id = "github-dormant-users/arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  to = aws_iam_role_policy_attachment.github_dormant_users_cloudwatch_logs_full_access_attachment
}

import {
  id = "github-dormant-users/arn:aws:iam::aws:policy/CloudWatchApplicationInsightsFullAccess"
  to = aws_iam_role_policy_attachment.github_dormant_users_cloudwatch_app_insights_full_access_attachment
}

resource "aws_iam_role" "github_dormant_users_role" {
  name               = "github-dormant-users"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role_policy_document.json
}

data "aws_iam_policy_document" "auth0_kms_policy_document" {
  statement {
    sid    = "AllowKMS"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [ aws_kms_key.auth0_log_group_key.arn ]
  }
}

resource "aws_iam_policy" "auth0_kms_policy" {
  name        = "Auth0KMSPolicy"
  description = "Policy for Auth0 KMS key"
  policy = data.aws_iam_policy_document.auth0_kms_policy_document
}

resource "aws_iam_role_policy_attachment" "auth0_kms_attachment" {
  role       = aws_iam_role.github_dormant_users_role.name
  policy_arn = aws_iam_policy.auth0_kms_policy.arn
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
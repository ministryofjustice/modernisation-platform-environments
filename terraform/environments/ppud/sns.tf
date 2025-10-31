##########################################################
# SNS Topics, Subscriptions, Policies and Policy Documents
##########################################################

#########################
# Development Environment
#########################

########################################################################
# SNS topic, subscription, policy & document for Cloudwatch Alarms - DEV
########################################################################

resource "aws_sns_topic" "cw_dev_alerts" {
  # checkov:skip=CKV_AWS_26: "SNS topic encryption is not required as no sensitive data is processed through it"
  count = local.is-development == true ? 1 : 0
  name  = "ppud-dev-cw-alerts"
}

resource "aws_sns_topic_subscription" "cw_dev_subscription" {
  count     = local.is-development == true ? 1 : 0
  topic_arn = aws_sns_topic.cw_dev_alerts[0].arn
  protocol  = "email"
  endpoint  = "PPUDAlerts@colt.net"
}

resource "aws_sns_topic_policy" "cw_dev_topic_policy" {
  count  = local.is-development == true ? 1 : 0
  arn    = aws_sns_topic.cw_dev_alerts[0].arn
  policy = data.aws_iam_policy_document.cw_dev_topic_policy_document[0].json
}

data "aws_iam_policy_document" "cw_dev_topic_policy_document" {
  count     = local.is-development == true ? 1 : 0
  policy_id = "cw_dev_sns_topic_policy_document"

  statement {
    sid    = "cw_dev_statement_id"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
    resources = [
      aws_sns_topic.cw_dev_alerts[0].arn
    ]
  }
}

##############################################################################
# SNS topic, subscription, policy & document for S3 Bucket Notifications - DEV
##############################################################################

resource "aws_sns_topic" "s3_bucket_notifications_dev" {
  # checkov:skip=CKV_AWS_26: "SNS topic encryption is not required as no sensitive data is processed through it"
  count = local.is-development == true ? 1 : 0
  name  = "s3_bucket_notifications_dev"
}

resource "aws_sns_topic_policy" "s3_bucket_notifications_dev" {
  count  = local.is-development == true ? 1 : 0
  arn    = aws_sns_topic.s3_bucket_notifications_dev[0].arn
  policy = data.aws_iam_policy_document.sns_topic_policy_s3_notifications_dev[0].json
}

resource "aws_sns_topic_subscription" "s3_bucket_notifications_dev_subscription" {
  count     = local.is-development == true ? 1 : 0
  topic_arn = aws_sns_topic.s3_bucket_notifications_dev[0].arn
  protocol  = "email"
  endpoint  = "PPUDAlerts@colt.net"
}

data "aws_iam_policy_document" "sns_topic_policy_s3_notifications_dev" {
  count     = local.is-development == true ? 1 : 0
  policy_id = "s3_bucket_notifications_dev"
  statement {
    sid = "S3-Publish-SNS"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    effect = "Allow"
    actions = [
      "SNS:Publish"
    ]

    condition {
      test     = "ArnLike"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:s3:::moj-log-files-dev"]
    }

    resources = [
      aws_sns_topic.s3_bucket_notifications_dev[0].arn
    ]
  }
}


##################################################################
# SNS topic, subscription, policy & document for SES Logging - DEV
##################################################################

resource "aws_sns_topic" "ses_logging_dev" {
  # checkov:skip=CKV_AWS_26: "SNS topic encryption is not required as no sensitive data is processed through it"
  count = local.is-development == true ? 1 : 0
  name  = "ppud-ses-logging-dev"
}

resource "aws_sns_topic_subscription" "ses_logging_subscription_dev" {
  count     = local.is-development == true ? 1 : 0
  topic_arn = aws_sns_topic.ses_logging_dev[0].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.terraform_lambda_func_ses_logging_dev[0].arn
}

resource "aws_sns_topic_policy" "ses_logging_dev_topic_policy" {
  count  = local.is-development == true ? 1 : 0
  arn    = aws_sns_topic.ses_logging_dev[0].arn
  policy = data.aws_iam_policy_document.ses_logging_dev_topic_policy_document[0].json
}

data "aws_iam_policy_document" "ses_logging_dev_topic_policy_document" {
  count     = local.is-development == true ? 1 : 0
  policy_id = "ses_logging_dev_sns_topic_policy_document"

  statement {
    sid    = "AllowSESPublish"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }
    actions = [
      "SNS:Publish"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
    resources = [
      aws_sns_topic.ses_logging_dev[0].arn
    ]
  }
}

###########################
# Preproduction Environment
###########################

########################################################################
# SNS topic, subscription, policy & document for Cloudwatch Alarms - UAT
########################################################################

resource "aws_sns_topic" "cw_uat_alerts" {
  # checkov:skip=CKV_AWS_26: "SNS topic encryption is not required as no sensitive data is processed through it"
  count = local.is-preproduction == true ? 1 : 0
  name  = "ppud-uat-cw-alerts"
}

resource "aws_sns_topic_subscription" "cw_uat_subscription" {
  count     = local.is-preproduction == true ? 1 : 0
  topic_arn = aws_sns_topic.cw_uat_alerts[0].arn
  protocol  = "email"
  endpoint  = "PPUDAlerts@colt.net"
}

resource "aws_sns_topic_policy" "cw_uat_topic_policy" {
  count  = local.is-preproduction == true ? 1 : 0
  arn    = aws_sns_topic.cw_uat_alerts[0].arn
  policy = data.aws_iam_policy_document.cw_uat_topic_policy_document[0].json
}

data "aws_iam_policy_document" "cw_uat_topic_policy_document" {
  count     = local.is-preproduction == true ? 1 : 0
  policy_id = "cw_uat_sns_topic_policy_document"

  statement {
    sid    = "cw_uat_statement_id"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
    resources = [
      aws_sns_topic.cw_uat_alerts[0].arn
    ]
  }
}

##############################################################################
# SNS topic, subscription, policy & document for S3 Bucket Notifications - UAT
##############################################################################

resource "aws_sns_topic" "s3_bucket_notifications_uat" {
  # checkov:skip=CKV_AWS_26: "SNS topic encryption is not required as no sensitive data is processed through it"
  count = local.is-preproduction == true ? 1 : 0
  name  = "s3_bucket_notifications_uat"
}

resource "aws_sns_topic_policy" "s3_bucket_notifications_uat" {
  count  = local.is-preproduction == true ? 1 : 0
  arn    = aws_sns_topic.s3_bucket_notifications_uat[0].arn
  policy = data.aws_iam_policy_document.sns_topic_policy_s3_notifications_uat[0].json
}

resource "aws_sns_topic_subscription" "s3_bucket_notifications_uat_subscription" {
  count     = local.is-preproduction == true ? 1 : 0
  topic_arn = aws_sns_topic.s3_bucket_notifications_uat[0].arn
  protocol  = "email"
  endpoint  = "PPUDAlerts@colt.net"
}

data "aws_iam_policy_document" "sns_topic_policy_s3_notifications_uat" {
  count     = local.is-preproduction == true ? 1 : 0
  policy_id = "s3_bucket_notifications_uat"
  statement {
    sid = "S3-Publish-SNS"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    effect = "Allow"
    actions = [
      "SNS:Publish"
    ]

    condition {
      test     = "ArnLike"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:s3:::moj-log-files-uat"]
    }

    resources = [
      aws_sns_topic.s3_bucket_notifications_uat[0].arn
    ]
  }
}

##################################################################
# SNS topic, subscription, policy & document for SES Logging - UAT
##################################################################

resource "aws_sns_topic" "ses_logging_uat" {
  # checkov:skip=CKV_AWS_26: "SNS topic encryption is not required as no sensitive data is processed through it"
  count = local.is-preproduction == true ? 1 : 0
  name  = "ppud-ses-logging-uat"
}

resource "aws_sns_topic_subscription" "ses_logging_subscription_uat" {
  count     = local.is-preproduction == true ? 1 : 0
  topic_arn = aws_sns_topic.ses_logging_uat[0].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.terraform_lambda_func_ses_logging_uat[0].arn
}

resource "aws_sns_topic_policy" "ses_logging_uat_topic_policy" {
  count  = local.is-preproduction == true ? 1 : 0
  arn    = aws_sns_topic.ses_logging_uat[0].arn
  policy = data.aws_iam_policy_document.ses_logging_uat_topic_policy_document[0].json
}

data "aws_iam_policy_document" "ses_logging_uat_topic_policy_document" {
  count     = local.is-preproduction == true ? 1 : 0
  policy_id = "ses_logging_uat_sns_topic_policy_document"

  statement {
    sid    = "AllowSESPublish"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }
    actions = [
      "SNS:Publish"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
    resources = [
      aws_sns_topic.ses_logging_uat[0].arn
    ]
  }
}

########################
# Production Environment
########################

#########################################################################
# SNS topic, subscription, policy & document for Cloudwatch Alarms - PROD
#########################################################################

resource "aws_sns_topic" "cw_alerts" {
  # checkov:skip=CKV_AWS_26: "SNS topic encryption is not required as no sensitive data is processed through it"
  count = local.is-production == true ? 1 : 0
  name  = "ppud-prod-cw-alerts"
}

resource "aws_sns_topic_subscription" "cw_subscription" {
  count     = local.is-production == true ? 1 : 0
  topic_arn = aws_sns_topic.cw_alerts[0].arn
  protocol  = "email"
  endpoint  = "PPUDAlerts@colt.net"
  #  endpoint  = aws_secretsmanager_secret_version.support_email_account[0].secret_string
}

# SNS topic subscriptions to be implemented temporarily over the Christmas period or during other periods of low staffing.

/*
resource "aws_sns_topic_subscription" "cw_sms_subscription" {
  count     = local.is-production == true ? 1 : 0
  topic_arn = aws_sns_topic.cw_alerts[0].arn
  protocol  = "sms"
  endpoint  = "+447903642202" # Nick Buckingham
}

resource "aws_sns_topic_subscription" "cw_sms_subscription1" {
  count     = local.is-production == true ? 1 : 0
  topic_arn = aws_sns_topic.cw_alerts[0].arn
  protocol  = "sms"
  endpoint  = "+447879063551" # Gabriella Browning
}

resource "aws_sns_topic_subscription" "cw_sms_subscription2" {
  count     = local.is-production == true ? 1 : 0
  topic_arn = aws_sns_topic.cw_alerts[0].arn
  protocol  = "sms"
  endpoint  = "+447584337970" # David Savage (work)
}

resource "aws_sns_topic_subscription" "cw_sms_subscription3" {
  count     = local.is-production == true ? 1 : 0
  topic_arn = aws_sns_topic.cw_alerts[0].arn
  protocol  = "sms"
  endpoint  = "+447884053737" # David Savage (personal)
}

resource "aws_sns_topic_subscription" "cw_sms_subscription4" {
  count     = local.is-production == true ? 1 : 0
  topic_arn = aws_sns_topic.cw_alerts[0].arn
  protocol  = "sms"
  endpoint  = "+447887576466" # Kofi Owusu-nimoh
}
*/

resource "aws_sns_topic_policy" "cw_prod_topic_policy" {
  count  = local.is-production == true ? 1 : 0
  arn    = aws_sns_topic.cw_alerts[0].arn
  policy = data.aws_iam_policy_document.cw_prod_topic_policy_document[0].json
}

data "aws_iam_policy_document" "cw_prod_topic_policy_document" {
  count     = local.is-production == true ? 1 : 0
  policy_id = "cw_prod_sns_topic_policy_document"

  statement {
    sid    = "cw_prod_statement_id"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
    resources = [
      aws_sns_topic.cw_alerts[0].arn
    ]
  }
}

###############################################################################
# SNS topic, subscription, policy & document for S3 Bucket Notifications - PROD
###############################################################################

resource "aws_sns_topic" "s3_bucket_notifications_prod" {
  # checkov:skip=CKV_AWS_26: "SNS topic encryption is not required as no sensitive data is processed through it"
  count = local.is-production == true ? 1 : 0
  name  = "s3_bucket_notifications_prod"
}

resource "aws_sns_topic_policy" "s3_bucket_notifications_prod" {
  count  = local.is-production == true ? 1 : 0
  arn    = aws_sns_topic.s3_bucket_notifications_prod[0].arn
  policy = data.aws_iam_policy_document.sns_topic_policy_s3_notifications_prod[0].json
}

resource "aws_sns_topic_subscription" "s3_bucket_notifications_prod_subscription" {
  count     = local.is-production == true ? 1 : 0
  topic_arn = aws_sns_topic.s3_bucket_notifications_prod[0].arn
  protocol  = "email"
  endpoint  = "PPUDAlerts@colt.net"
}

data "aws_iam_policy_document" "sns_topic_policy_s3_notifications_prod" {
  count     = local.is-production == true ? 1 : 0
  policy_id = "s3_bucket_notifications_prod"
  statement {
    sid = "S3-Publish-SNS"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    effect = "Allow"
    actions = [
      "SNS:Publish"
    ]

    condition {
      test     = "ArnLike"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:s3:::moj-log-files-prod"]
    }

    resources = [
      aws_sns_topic.s3_bucket_notifications_prod[0].arn
    ]
  }
}

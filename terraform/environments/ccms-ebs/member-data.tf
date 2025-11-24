#### This file can be used to store data specific to the member account ####

## AMI data blocks
# data "aws_ami" "oracle_base_prereqs" {
#   most_recent = true
#   owners      = [local.application_data.accounts[local.environment].ami_owner]

#   filter {
#     name   = "name"
#     values = [local.application_data.accounts[local.environment].orace_base_prereqs_ami_name]
#   }
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

# data "aws_ami" "oracle_db" {
#   most_recent = true
#   owners      = [local.application_data.accounts[local.environment].ami_owner]

#   filter {
#     name   = "name"
#     values = [local.application_data.accounts[local.environment].orace_db_ami_name]
#   }
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

# data "aws_ami" "webgate" {
#   most_recent = true
#   owners      = [local.application_data.accounts[local.environment].ami_owner]

#   filter {
#     name   = "name"
#     values = [local.application_data.accounts[local.environment].webgate_ami_name]
#   }
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

# data "aws_ami" "accessgate" {
#   most_recent = true
#   owners      = [local.application_data.accounts[local.environment].ami_owner]

#   filter {
#     name   = "name"
#     values = [local.application_data.accounts[local.environment].accessgate_ami_name]
#   }
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

## SNS IAM Policies

# The policies below are not used. Saved for reference.

data "aws_iam_policy_document" "sns_topic_policy_ec2cw" {
  version = "2012-10-17"
  statement {
    sid    = "EventsAllowPublishSnsTopic"
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]
    resources = [
      aws_sns_topic.cw_alerts.arn
    ]
    principals {
      type = "Service"
      identifiers = [
        "cloudwatch.amazonaws.com",
      ]
    }
  }
  
}

# data "aws_iam_policy_document" "sns_topic_policy_s3" {
#   policy_id = "SnsTopicId"
#   statement {
#     actions = [
#       "SNS:AddPermission",
#       "SNS:DeleteTopic",
#       "SNS:GetTopicAttributes",
#       "SNS:ListSubscriptionsByTopic",
#       "SNS:Publish",
#       "SNS:Receive",
#       "SNS:SetTopicAttributes",
#       "SNS:Subscribe",
#     ]
#     effect = "Allow"
#     resources = [
#       aws_sns_topic.s3_topic.arn
#     ]
#     sid = "statement1"
#     principals {
#       identifiers = [
#         "*",
#       ]
#       type        = "AWS"
#     }
#   }
# }

# data "aws_iam_policy_document" "sns_topic_policy_ddos" {
#   policy_id = "SnsTopicId"
#   statement {
#     sid = "statement1"
#     principals {
#       type        = "AWS"
#       identifiers = ["*"]
#     }
#     effect = "Allow"
#     actions = [
#       "SNS:GetTopicAttributes",
#       "SNS:SetTopicAttributes",
#       "SNS:AddPermission",
#       "SNS:DeleteTopic",
#       "SNS:Subscribe",
#       "SNS:ListSubscriptionsByTopic",
#       "SNS:Publish",
#       "SNS:Receive"
#     ]
#     resources = [
#       aws_sns_topic.ddos_alarm.arn
#     ]
#   }
# }

## SECRETS
data "aws_secretsmanager_secret" "support_email_account" {
  name = "support_email_account"
  depends_on = [
    aws_secretsmanager_secret.support_email_account
  ]
}

data "aws_secretsmanager_secret_version" "support_email_account" {
  secret_id = data.aws_secretsmanager_secret.support_email_account.id
  depends_on = [
    aws_secretsmanager_secret_version.support_email_account
  ]
}

## SECURITY GROUPS
data "aws_security_groups" "all_security_groups" {
  filter {
    name   = "tag:Name"
    values = ["*ccms*"]
  }
}

## S3 NOTIFICATIONS
data "aws_iam_policy_document" "s3_topic_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = ["arn:aws:sns:*:*:s3-event-notification-topic"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        module.s3-bucket.bucket.arn,
        module.s3-bucket-logging.bucket.arn,
        module.s3-bucket-dbbackup.bucket.arn
      ]
    }
  }
}

## PROD CERT
data "aws_route53_zone" "application-zone" {
  provider = aws.core-network-services

  name         = "ccms-ebs.service.justice.gov.uk."
  private_zone = false
}

## GANDI CERT
data "aws_acm_certificate" "gandi_cert" {
  domain   = local.application_data.accounts[local.environment].lz_domain_name
  statuses = ["ISSUED"]
}

## PROD DNS
data "aws_route53_zone" "prod-network-services" {
  provider = aws.core-network-services

  name         = "ccms-ebs.service.justice.gov.uk."
  private_zone = false
}
data "aws_route53_zone" "application_zone" {
  provider     = aws.core-network-services
  name         = "ccms-ebs.service.justice.gov.uk."
  private_zone = false
}

data "aws_route53_zone" "legalservices" {
  provider     = aws.core-network-services
  name         = "legalservices.gov.uk"
  private_zone = false
}

data "aws_route53_zone" "laa" {
  provider     = aws.core-network-services
  name         = "laa.service.justice.gov.uk"
  private_zone = false
}

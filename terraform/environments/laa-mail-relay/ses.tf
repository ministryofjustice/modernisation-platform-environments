resource "aws_sesv2_email_identity" "postfix" {
  email_identity         = data.aws_route53_zone.external.name
  configuration_set_name = local.environment == "production" ? aws_sesv2_configuration_set.postfix[0].configuration_set_name : null
  dkim_signing_attributes {
    next_signing_key_length = "RSA_1024_BIT"
  }
  tags = local.tags
}

resource "aws_sesv2_email_identity_policy" "postfix" {
  email_identity = aws_sesv2_email_identity.postfix.email_identity
  policy_name    = "ssvc-ses-permission-${local.environment}"

  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": [
        "ses:SendEmail",
        "ses:SendRawEmail"
      ],
      "Resource": "arn:aws:ses:eu-west-2:${data.aws_caller_identity.current.account_id}:identity/${data.aws_route53_zone.external.name}"
    }
  ]
}
EOF
}

resource "aws_route53_record" "ses_dkim" {
  provider = aws.core-vpc
  count    = 3
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${aws_sesv2_email_identity.postfix.dkim_signing_attributes[0].tokens[count.index]}._domainkey.${data.aws_route53_zone.external.name}"
  type     = "CNAME"
  ttl      = "600"
  records  = ["${aws_sesv2_email_identity.postfix.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"]
}


resource "aws_route53_record" "ses_dmarc" {
  count    = contains(["development"], local.environment) ? 0 : 1
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "_dmarc.${data.aws_route53_zone.external.name}"
  type     = "TXT"
  ttl      = "600"
  records  = ["v=DMARC1;p=none;sp=none;fo=1;rua=mailto:dmarc-rua@dmarc.service.gov.uk,mailto:dmarc-rua@digital.justice.gov.uk;ruf=mailto:dmarc-ruf@dmarc.service.gov.uk,mailto:dmarc-ruf@digital.justice.gov.uk"]
}

### SMTP IAM User

resource "aws_iam_user" "smtp" {
  name = "${local.application_name}-${local.application_data.accounts[local.environment].env_short}-user"
  tags = local.tags
}

resource "aws_iam_access_key" "smtp" {
  user = aws_iam_user.smtp.name
}

data "aws_iam_policy_document" "smtp_user" {
  statement {
    effect    = "Allow"
    actions   = ["ses:SendRawEmail"]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "smtp_user" {
  name   = "AmazonSesSendingAccess"
  user   = aws_iam_user.smtp.name
  policy = data.aws_iam_policy_document.smtp_user.json
}

### SMTP Secrets Creation

resource "aws_secretsmanager_secret" "smtp_user" {
  name        = "postfix/app/APP_DATA_MIGRATION_SMTP_USER"
  description = "IAM user access key for SMTP"
  tags = merge(
    local.tags,
    { "Name" = "postfix/app/APP_DATA_MIGRATION_SMTP_USER" }
  )
}

resource "aws_secretsmanager_secret_version" "smtp_user" {
  secret_id     = aws_secretsmanager_secret.smtp_user.id
  secret_string = aws_iam_access_key.smtp.id
}

resource "aws_secretsmanager_secret" "smtp_password" {
  name        = "postfix/app/APP_DATA_MIGRATION_SMTP_PASSWORD"
  description = "IAM user access secret for SMTP"
  tags = merge(
    local.tags,
    { "Name" = "postfix/app/APP_DATA_MIGRATION_SMTP_PASSWORD" }
  )
}

resource "aws_secretsmanager_secret_version" "smtp_password" {
  secret_id     = aws_secretsmanager_secret.smtp_password.id
  secret_string = aws_iam_access_key.smtp.ses_smtp_password_v4
}

resource "aws_secretsmanager_secret" "smtp_sesans" {
  name        = "postfix/app/SESANS_MP"
  description = "Secret to pull from Ansible code from https://github.com/ministryofjustice/laa-aws-postfix-smtp"
  tags = merge(
    local.tags,
    { "Name" = "postfix/app/SESANS_MP" }
  )
}

resource "aws_secretsmanager_secret" "smtp_sesrsap" {
  name        = "postfix/app/SESRSAP"
  description = ""
  tags = merge(
    local.tags,
    { "Name" = "postfix/app/SESRSAP" }
  )
}

resource "aws_secretsmanager_secret" "smtp_sesrsa" {
  name        = "postfix/app/SESRSA"
  description = ""
  tags = merge(
    local.tags,
    { "Name" = "postfix/app/SESRSA" }
  )
}


###################################
## Production set up
###################################

## TODO Create Kinesis Data Firehose and IAM role for Production, then enable below to set event destination

resource "aws_sesv2_configuration_set" "postfix" {
  count                  = contains(["production"], local.environment) ? 1 : 0
  configuration_set_name = "${local.application_name}-configuration-set"

  delivery_options {
    tls_policy = "OPTIONAL"
  }

  reputation_options {
    reputation_metrics_enabled = true
  }

  tags = local.tags
}

# resource "aws_sesv2_configuration_set_event_destination" "postfix" {
#   configuration_set_name = aws_sesv2_configuration_set.postfix.configuration_set_name
#   event_destination_name = "ses-reputation-events-firehose"

#   event_destination {
#     kinesis_firehose_destination {
#       delivery_stream_arn = aws_kinesis_firehose_delivery_stream.example.arn
#       iam_role_arn        = aws_iam_role.example.arn
#     }

#     enabled              = true
#     matching_event_types = ["SEND", TBC]
#   }
# }
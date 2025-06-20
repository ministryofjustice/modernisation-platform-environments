# SES SMTP Integration from MAATDB


# Get the Route 53 hosted zone for the domain
data "aws_route53_zone" "zone" {
  provider     = aws.core-network-services
  name         = local.hosted_zone
  private_zone = false
}

locals {

  # SES Specific Locals
  hosted_zone = local.application_data.accounts[local.environment].hosted_zone
  ses_domain = local.application_data.accounts[local.environment].ses_domain
   
  mx_zone_id = try(data.aws_route53_zone.zone.zone_id, null)

}

resource "aws_iam_user" "smtp_user" {
  # checkov:skip=CKV_AWS_273:Required for SMTP
  count = local.build_ses ? 1 : 0
  name  = "${local.application_name}-smtp-user"
  tags = merge(
    local.tags,
    {
       Name = "${local.application_name}-smtp-user"
    }
  )
}

resource "aws_iam_access_key" "smtp_user_key" {
  count = local.build_ses ? 1 : 0
  user  = aws_iam_user.smtp_user[0].name
}

resource "aws_secretsmanager_secret" "smtp_access_key_secret" {
  #checkov:skip=CKV_AWS_149:"Secret to be manually rotated"
  #checkov:skip=CKV2_AWS_57:"Secret to be manually rotated"
  count = local.build_ses ? 1 : 0
  name  = "ses-smtp-user-access-key"
  tags = merge(
    local.tags,
    {
      Name = "ses-smtp-user-access-key"
    }
  )
}

resource "aws_secretsmanager_secret_version" "smtp_access_key_secret_version" {
  count      = local.build_ses ? 1 : 0
  secret_id  = aws_secretsmanager_secret.smtp_access_key_secret[0].id
  secret_string = jsonencode({
    IAM_ACCESS_KEY_ID     = aws_iam_access_key.smtp_user_key[0].id
    IAM_SECRET_ACCESS_KEY = aws_iam_access_key.smtp_user_key[0].secret
  })
}

resource "aws_iam_user_policy" "smtp_user_policy" {
  # checkov:skip=CKV_AWS_40:Policy attached to User due to Modernisation Platform restrictions
  # checkov:skip=CKV_AWS_290:Policy does not deal with write access
  count  = local.build_ses ? 1 : 0
  name   = "${local.application_name}-SMTPUserPolicy"
  user   = aws_iam_user.smtp_user[0].name
  policy = data.aws_iam_policy_document.smtp_user_policy.json
}

data "aws_iam_policy_document" "smtp_user_policy" {
  statement {
    effect = "Allow"
    actions = ["ses:SendRawEmail"]
    resources = length(aws_ses_domain_identity.domain) > 0 ? [aws_ses_domain_identity.domain[0].arn] : []
  }
}

# These resources generate the SMTP password required to access SES SMTP.

resource "aws_secretsmanager_secret" "smtp_credentials" {
  #checkov:skip=CKV_AWS_149:"Secret to be manually rotated"
  #checkov:skip=CKV2_AWS_57:"Secret to be manually rotated"
  count = local.build_ses ? 1 : 0
  name  = "ses-smtp-credentials"
  tags = merge(
    local.tags,
    {
      Name = "ses-smtp-credentials"
    }
  )
}

resource "aws_secretsmanager_secret_version" "smtp_secret_version" {
  count        = local.build_ses ? 1 : 0
  secret_id    = aws_secretsmanager_secret.smtp_credentials[0].id

  secret_string = jsonencode({
    SMTP_USERNAME = aws_iam_access_key.smtp_user_key[0].id
    SMTP_PASSWORD = aws_iam_access_key.smtp_user_key[0].ses_smtp_password_v4
  })
}


#  SES & Route53 resources

# SES domain identity
resource "aws_ses_domain_identity" "domain" {
  count  = local.build_ses ? 1 : 0
  domain = local.ses_domain
}

# Add SES verification TXT record to Route 53
resource "aws_route53_record" "verification" {
  provider = aws.core-network-services
  count   = local.build_ses ? 1 : 0
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "_amazonses.${local.ses_domain}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.domain[0].verification_token]
}

# Enable DKIM
resource "aws_ses_domain_dkim" "dkim" {
  count  = local.build_ses ? 1 : 0
  domain = aws_ses_domain_identity.domain[0].domain
}

# Add DKIM CNAME records to Route 53
resource "aws_route53_record" "dkim" {
  provider = aws.core-network-services
  count   = local.build_ses ? 3 : 0
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${aws_ses_domain_dkim.dkim[0].dkim_tokens[count.index]}._domainkey.${local.ses_domain}"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.dkim[0].dkim_tokens[count.index]}.dkim.amazonses.com"]
}



# This adds email receipt verification for the primary laareporders address. This is required if SES is in sandbox mode - the default for a new account.

resource "aws_s3_bucket" "ses_incoming_email" {
  #checkov:skip=CKV_AWS_149:"To be ignored for now - bucket is only used to capture an single validation email"
  #checkov:skip=CKV2_AWS_61:"See above"
  #checkov:skip=CKV2_AWS_57:"See above"
  #checkov:skip=CKV2_AWS_62:"See above"
  #checkov:skip=CKV_AWS_21:"See above"
  #checkov:skip=CKV2_AWS_6:"See above"
  #checkov:skip=CKV_AWS_144:"See above"
  #checkov:skip=CKV_AWS_18:"See above"
  #checkov:skip=CKV_AWS_145:"See above"


  bucket = "ses-inbound-verification-${local.application_name}-${local.environment}"
  force_destroy = true

  tags = merge(
    local.tags,
    {
      Name = "ses-inbound-verification-${local.application_name}-${local.environment}"
    }
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ses_incoming_email" {
  bucket = aws_s3_bucket.ses_incoming_email.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = data.aws_kms_key.general_shared.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "default" {
  bucket = aws_s3_bucket.ses_incoming_email.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_policy" "allow_ses" {
  bucket = aws_s3_bucket.ses_incoming_email.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # 1. Allow SES to write email
      {
        Effect = "Allow",
        Principal = {
          Service = "ses.amazonaws.com"
        },
        Action = "s3:PutObject",
        Resource = "${aws_s3_bucket.ses_incoming_email.arn}/*",
        Condition = {
          StringEquals = {
            "aws:Referer" = local.environment_management.account_ids[terraform.workspace]
          }
        }
      },
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:root"
        },
        Action = [
          "s3:GetObject"
        ],
        Resource = "${aws_s3_bucket.ses_incoming_email.arn}/*"
      },
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:root"
        },
        Action = [
          "s3:ListBucket"
        ],
        Resource = aws_s3_bucket.ses_incoming_email.arn
        Condition = {
          StringLike = {
            "s3:prefix" = ["inbound/*"]
          }
        }
      }
    ]
  })
}



resource "aws_ses_receipt_rule_set" "default" {
  rule_set_name = "default-receipt-rule-set"
}

resource "aws_ses_receipt_rule" "accept_verification_email" {
  depends_on = [ aws_s3_bucket.ses_incoming_email ]
  name          = "receive-noreply"
  rule_set_name = aws_ses_receipt_rule_set.default.rule_set_name
  recipients    = ["laareporders@${local.ses_domain}"]
  enabled       = true
  scan_enabled  = true
  tls_policy    = "Optional"

  s3_action {
    position          = 1
    bucket_name       = aws_s3_bucket.ses_incoming_email.bucket
    object_key_prefix = "inbound/"
  }
}

# This routes incoming email to S3 solely to capture any validation emails based on the above aws_ses_receipt_rule. It is only to be used in the initial set up.

resource "aws_route53_record" "ses_inbound_mx" {
  count = local.route_ses_s3 && local.mx_zone_id != null ? 1 : 0
  provider = aws.core-network-services
  zone_id = local.mx_zone_id
  name    = local.ses_domain
  type    = "MX"
  ttl     = 300

  records = [
    "10 inbound-smtp.eu-west-2.amazonaws.com."
  ]

  depends_on = [
    aws_ses_domain_identity.domain,
    aws_ses_receipt_rule_set.default,
    aws_s3_bucket.ses_incoming_email
  ]
}

# Outputs
output "smtp_username" {
  description = "The IAM access key ID for SMTP user"
  value       = length(aws_iam_access_key.smtp_user_key) > 0 ? aws_iam_access_key.smtp_user_key[0].id : null
}

output "smtp_password" {
  description = "The SMTP password for SES (derived from access key)"
  value       = length(aws_iam_access_key.smtp_user_key) > 0 ? aws_iam_access_key.smtp_user_key[0].ses_smtp_password_v4 : null
  sensitive   = true
}
resource "aws_ses_domain_identity" "domain_identity" {
  domain = local.application_data.accounts[local.environment].ses_domain_identity
}

resource "aws_ses_domain_dkim" "domain_identity" {
  domain = aws_ses_domain_identity.domain_identity.domain
}

data "aws_iam_policy_document" "ses_identity_policy" {
  statement {
    actions   = ["SES:SendEmail", "SES:SendRawEmail"]
    resources = [aws_ses_domain_identity.domain_identity.arn]

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
  }
}

resource "aws_ses_identity_policy" "identity_policy" {
  identity = aws_ses_domain_identity.domain_identity.arn
  name     = "default-policy"
  policy   = data.aws_iam_policy_document.ses_identity_policy.json
}

resource "aws_ses_configuration_set" "default_configuration_set" {
  name = "default-configuration-set"

  delivery_options {
    tls_policy = "Optional"
  }
  reputation_metrics_enabled = true
  sending_enabled            = true
}

# TO DO: Kinesis configuration (including S3 bucket, IAM role and policy, ...).
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_firehose_delivery_stream
#
# resource "aws_ses_event_destination" "kinesis" {
#   name                   = "ses-reputation-events-firehose"
#   configuration_set_name = aws_ses_configuration_set.default_configuration_set.name
#   enabled                = true
#   matching_types         = [ "bounce", "click", "complaint", "delivery", "open", "reject", "renderingFailure", "send" ]
# 
#   kinesis_destination {
#     stream_arn = aws_kinesis_firehose_delivery_stream.example.arn
#     role_arn   = aws_iam_role.example.arn
#   }
# }

output "ses_verification_token" {
  description = "SES verification token"
  value       = aws_ses_domain_identity.domain_identity.verification_token
}

output "ses_domain_dkim" {
  description = "SES domain DKIM"
  value       = aws_ses_domain_dkim.domain_identity.dkim_tokens
}
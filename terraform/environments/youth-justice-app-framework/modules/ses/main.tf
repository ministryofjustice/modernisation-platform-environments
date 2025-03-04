resource "aws_ses_domain_identity" "main" {
  for_each = toset(var.ses_domain_identities)
  domain   = each.value
}

#resource "aws_ses_domain_identity_verification" "main" {
#  for_each = toset(var.ses_domain_identities)
#  domain   = aws_ses_domain_identity.main[each.value].domain
#
#  depends_on = [aws_route53_record.ses_verification, aws_route53_record.ses_dkim, aws_route53_record.ses_dkim_2, aws_route53_record.ses_dkim_3]
#}

resource "aws_ses_domain_dkim" "main" {
  for_each = toset(var.ses_domain_identities)
  domain   = aws_ses_domain_identity.main[each.value].domain
}


#####################
# SES SMTP User
#####################

resource "aws_iam_user" "ses_smtp_user" {
  name = "${var.environment}-${var.project_name}-smtp-user"
}

resource "aws_iam_access_key" "ses_smtp_user" {
  user = aws_iam_user.ses_smtp_user.name
}

resource "aws_iam_user_policy" "ses_smtp_user" {
  name = "${var.environment}-${var.project_name}-ses-smtp-user-policy"
  user = aws_iam_user.ses_smtp_user.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ses:SendRawEmail",
          "ses:SendEmail"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_secretsmanager_secret" "ses_user_secret" {
  #checkov:skip=CKV2_AWS_57:todo add rotation if needed
  name        = "${var.project_name}-ses-user"
  description = "key credentials for ses user"
  kms_key_id  = var.key_id
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "ses_user_secret" {
  secret_id = aws_secretsmanager_secret.ses_user_secret.id
  secret_string = jsonencode({
    username = aws_iam_access_key.ses_smtp_user.id,
    password = aws_iam_access_key.ses_smtp_user.secret
  })
}

resource "aws_sesv2_configuration_set" "ses_configuration_set" {
  configuration_set_name = format("%s-configuration-set", var.project_name)

  suppression_options {
    suppressed_reasons = [
      "BOUNCE",
      "COMPLAINT"
    ]
  }

  tags = var.tags
}


### Suppression list import
resource "null_resource" "import_suppression" {
  provisioner "local-exec" {
    command = "${path.module}/import_suppression.sh"
  }

  triggers = {
    always_run = "${timestamp()}" # Ensures it runs every time
  }
}

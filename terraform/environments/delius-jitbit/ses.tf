resource "aws_iam_user" "smtp_user" {
  name = "jitbit_smtp_user"
}

resource "aws_iam_access_key" "smtp_user" {
  user = aws_iam_user.smtp_user.name
}

data "aws_iam_policy_document" "ses_sender" {
  statement {
    actions   = ["ses:SendRawEmail"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ses_sender" {
  name        = "ses_sender"
  description = "Allows sending of e-mails via Simple Email Service"
  policy      = data.aws_iam_policy_document.ses_sender.json
}

resource "aws_iam_user_policy_attachment" "ses_sender" {
  user       = aws_iam_user.smtp_user.name
  policy_arn = aws_iam_policy.ses_sender.arn
}

resource "aws_secretsmanager_secret" "smtp_username" {
  name = "${var.networking[0].application}-smtp-user"
  tags = merge(
    local.tags,
    {
      Name = "${var.networking[0].application}-smtp-user"
    },
  )
}

resource "aws_secretsmanager_secret_version" "smtp_username" {
  secret_id     = aws_secretsmanager_secret.smtp_username.id
  secret_string = aws_iam_access_key.smtp_user.id
}

resource "aws_secretsmanager_secret" "smtp_password" {
  name = "${var.networking[0].application}-smtp-password"
  tags = merge(
    local.tags,
    {
      Name = "${var.networking[0].application}-smtp-password"
    },
  )
}

resource "aws_secretsmanager_secret_version" "smtp_password" {
  secret_id     = aws_secretsmanager_secret.smtp_password.id
  secret_string = aws_iam_access_key.smtp_user.ses_smtp_password_v4
}

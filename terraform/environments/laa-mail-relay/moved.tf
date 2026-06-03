# # moved blocks tell Terraform that existing non-indexed resources in state
# # (test/preprod/prod) are now indexed [0] due to count being added.
# # Without these, Terraform would destroy the existing resources and recreate them.
# # These are safe no-ops for dev (where these resources never existed in state).

# moved {
#   from = aws_instance.smtp
#   to   = aws_instance.smtp[0]
# }

# moved {
#   from = aws_route53_record.smtp
#   to   = aws_route53_record.smtp[0]
# }

# moved {
#   from = aws_secretsmanager_secret.smtp_password
#   to   = aws_secretsmanager_secret.smtp_password[0]
# }

# moved {
#   from = aws_secretsmanager_secret_version.smtp_password
#   to   = aws_secretsmanager_secret_version.smtp_password[0]
# }

# moved {
#   from = aws_secretsmanager_secret.smtp_sesrsa
#   to   = aws_secretsmanager_secret.smtp_sesrsa[0]
# }

# moved {
#   from = aws_secretsmanager_secret.smtp_sesrsap
#   to   = aws_secretsmanager_secret.smtp_sesrsap[0]
# }

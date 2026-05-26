# No password rotation required, therefore commenting it out

# resource "aws_secretsmanager_secret_rotation" "weblogic" {
#   secret_id           = aws_secretsmanager_secret.weblogic.id
#   rotation_lambda_arn = module.rotate_secrets_lambda.lambda_arn
#
#   rotation_rules {
#     automatically_after_days = 28
#   }
# }

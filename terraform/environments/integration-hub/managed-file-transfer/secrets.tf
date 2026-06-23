module "secrets_custom_idp_user" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  for_each = local.custom_idp_users

  # The custom IdP Lambda looks up each user's credentials at
  # "<secret_prefix><username>" (see lambda/custom-idp/idp_handler/app.py), so
  # every user must have their own secret. One secret per user also keeps the
  # blast radius small and makes per-user access auditing and rotation simpler.
  name                    = "${local.custom_idp_configuration.secret_prefix}${each.key}"
  description             = "${local.application_name} custom IdP POC credentials for ${each.key}"
  recovery_window_in_days = 7
  kms_key_id              = module.kms_secrets.key_arn
  create_policy           = true
  block_public_policy     = true
  ignore_secret_changes   = true

  policy_statements = {
    read = {
      sid = "AllowCIRolesToRead"
      principals = [{
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${data.aws_caller_identity.original_session.id}:role/MemberInfrastructureAccess"
        ]
      }]
      actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      resources = ["*"]
    }
  }

  secret_string = jsonencode({
    Password   = "replace-me"
    PublicKeys = ["replace-me"]
  })
}
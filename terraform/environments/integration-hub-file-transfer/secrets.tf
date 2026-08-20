module "secrets_file_dispatch_prefix" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  for_each = merge(local.environment_file_dispatch_prefixes...)

  name                    = each.key
  description             = "File dispatch configuration for the ${each.key} object key prefix"
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

  secret_string = jsonencode(each.value)
}

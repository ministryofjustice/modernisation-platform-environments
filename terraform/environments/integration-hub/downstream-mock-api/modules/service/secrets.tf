resource "random_password" "downstream_basic_auth_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

module "downstream_basic_auth_secret" {
  #checkov:skip=CKV_TF_1:Terraform Registry modules are version-pinned and do not support commit hash references
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  name                    = "${local.resource_name_prefix}-${local.environment}-basic-auth"
  description             = "Basic auth credentials for the downstream mock API"
  recovery_window_in_days = 7
  create_policy           = false
  block_public_policy     = true
  ignore_secret_changes   = true

  secret_string = jsonencode({
    username = "orchestration-client"
    password = random_password.downstream_basic_auth_password.result
  })

  tags = local.tags
}

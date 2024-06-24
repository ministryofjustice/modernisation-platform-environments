# Database Read Access
resource "aws_secretsmanager_secret" "dms_audit_endpoint_source" {
  name        = local.dms_audit_endpoint_source_secret_name
  description = "DMS Database Endpoint for Reading Audited Interaction Replication Data"
  kms_key_id  = var.account_config.kms_keys.general_shared
  tags        = var.tags
}

data "aws_iam_policy_document" "dms_audit_endpoint_source" {
  statement {
    sid    = "DMSRoleToReadTheSecret"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.delius_account_id}:role/DMSSecretsManagerAccessRole"]
    }
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.dms_audit_endpoint_source.arn]
  }
}

resource "aws_secretsmanager_secret_policy" "dms_audit_endpoint_source" {
  secret_arn = aws_secretsmanager_secret.dms_audit_endpoint_source.arn
  policy     = data.aws_iam_policy_document.dms_audit_endpoint_source.json
}

data "aws_secretsmanager_secret" "delius_core_application_passwords" {
  arn = var.delius_core_application_passwords_arn
}

data "aws_secretsmanager_secret_version" "delius_core_application_passwords" {
  secret_id = data.aws_secretsmanager_secret.delius_core_application_passwords.id
}

resource "aws_secretsmanager_secret_version" "dms_audit_endpoint_source_db" {
  count = var.dms_audit_source_endpoint.read_host == null ? 0 : 1
  secret_id = aws_secretsmanager_secret.dms_audit_endpoint_source.id
  secret_string = jsonencode({
    username = "delius_audit_dms_pool"
    password = jsondecode(data.aws_secretsmanager_secret_version.delius_core_application_passwords.secret_string)["delius_audit_dms_pool"]
    port = "1521"
    host = var.oracle_db_server_names[var.dms_audit_source_endpoint.read_host]
  })
}

resource "aws_secretsmanager_secret_version" "dms_user_endpoint_source_db" {
  count = var.dms_user_source_endpoint.read_host == null ? 0 : 1
  secret_id = aws_secretsmanager_secret.dms_audit_endpoint_source.id
  secret_string = jsonencode({
    username = "delius_audit_dms_pool"
    password = jsondecode(data.aws_secretsmanager_secret_version.delius_core_application_passwords.secret_string)["delius_audit_dms_pool"]
    port = "1521"
    host = var.oracle_db_server_names[var.dms_user_source_endpoint.read_host]
  })
}

# Although we could also create a Secret for the ASM Configuration
# this is not currently supported by Terraform aws_dms_endpoint
# and so we need to supply the configuration details inline instead.

# Database Write Access
resource "aws_secretsmanager_secret" "dms_audit_endpoint_target" {
  name        = local.dms_audit_endpoint_target_secret_name
  description = "DMS Database Endpoint for Writing Audited Interaction Replication Data"
  kms_key_id  = var.account_config.kms_keys.general_shared
  tags        = var.tags
}

data "aws_iam_policy_document" "dms_audit_endpoint_target" {
  statement {
    sid    = "DMSRoleToReadTheSecret"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.delius_account_id}:role/DMSSecretsManagerAccessRole"]
    }
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.dms_audit_endpoint_target.arn]
  }
}

resource "aws_secretsmanager_secret_policy" "dms_audit_endpoint_target" {
  secret_arn = aws_secretsmanager_secret.dms_audit_endpoint_target.arn
  policy     = data.aws_iam_policy_document.dms_audit_endpoint_target.json
}

resource "aws_secretsmanager_secret_version" "dms_audit_endpoint_target" {
  secret_id = aws_secretsmanager_secret.dms_audit_endpoint_target.id
}

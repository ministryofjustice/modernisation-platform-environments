#------------------------------------------------------------------------------
# Secrets definitions
#------------------------------------------------------------------------------
# Create secret
resource "random_password" "random_password" {

  length  = 32
  special = false
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "mojhub_cnnstr" {
  #checkov:skip=CKV_AWS_149
  name = "mojhub_cnnstr"
  tags = merge(
    local.tags,
    {
      Name = "mojhub_cnnstr"
    },
  )
}
resource "aws_secretsmanager_secret_version" "mojhub_cnnstr" {
  secret_id     = aws_secretsmanager_secret.mojhub_cnnstr.id
  secret_string = random_password.random_password.result
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "mojhub_membership" {
  #checkov:skip=CKV_AWS_149
  name = "mojhub_membership"
  tags = merge(
    local.tags,
    {
      Name = "mojhub_membership"
    },
  )
}
resource "aws_secretsmanager_secret_version" "mojhub_membership" {
  secret_id     = aws_secretsmanager_secret.mojhub_membership.id
  secret_string = random_password.random_password.result
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "govuk_notify_api_key" {
  #checkov:skip=CKV_AWS_149
  name = "govuk_notify_api_key"
  tags = merge(
    local.tags,
    {
      Name = "govuk_notify_api_key"
    },
  )
}
resource "aws_secretsmanager_secret_version" "govuk_notify_api_key" {
  secret_id     = aws_secretsmanager_secret.govuk_notify_api_key.id
  secret_string = random_password.random_password.result
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "os_vts_api_key" {
  #checkov:skip=CKV_AWS_149
  name = "os_vts_api_key"
  tags = merge(
    local.tags,
    {
      Name = "os_vts_api_key"
    },
  )
}
resource "aws_secretsmanager_secret_version" "os_vts_api_key" {
  secret_id     = aws_secretsmanager_secret.os_vts_api_key.id
  secret_string = random_password.random_password.result
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "ap_import_access_key_id" {
  #checkov:skip=CKV_AWS_149
  name = "ap_import_access_key_id"
  tags = merge(
    local.tags,
    {
      Name = "ap_import_access_key_id"
    },
  )
}
resource "aws_secretsmanager_secret_version" "ap_import_access_key_id" {
  secret_id     = aws_secretsmanager_secret.ap_import_access_key_id.id
  secret_string = random_password.random_password.result
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "ap_import_secret_access_key" {
  #checkov:skip=CKV_AWS_149
  name = "ap_import_secret_access_key"
  tags = merge(
    local.tags,
    {
      Name = "ap_import_secret_access_key"
    },
  )
}
resource "aws_secretsmanager_secret_version" "ap_import_secret_access_key" {
  secret_id     = aws_secretsmanager_secret.ap_import_secret_access_key.id
  secret_string = random_password.random_password.result
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "ap_export_access_key_id" {
  #checkov:skip=CKV_AWS_149
  name = "ap_export_access_key_id"
  tags = merge(
    local.tags,
    {
      Name = "ap_export_access_key_id"
    },
  )
}
resource "aws_secretsmanager_secret_version" "ap_export_access_key_id" {
  secret_id     = aws_secretsmanager_secret.ap_export_access_key_id.id
  secret_string = random_password.random_password.result
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "ap_export_secret_access_key" {
  #checkov:skip=CKV_AWS_149
  name = "ap_export_secret_access_key"
  tags = merge(
    local.tags,
    {
      Name = "ap_export_secret_access_key"
    },
  )
}
resource "aws_secretsmanager_secret_version" "ap_export_secret_access_key" {
  secret_id     = aws_secretsmanager_secret.ap_export_secret_access_key.id
  secret_string = random_password.random_password.result
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "pecs_basm_prod_access_key_id" {
  #checkov:skip=CKV_AWS_149
  name = "pecs_basm_prod_access_key_id"
  tags = merge(
    local.tags,
    {
      Name = "pecs_basm_prod_access_key_id"
    },
  )
}
resource "aws_secretsmanager_secret_version" "pecs_basm_prod_access_key_id" {
  secret_id     = aws_secretsmanager_secret.pecs_basm_prod_access_key_id.id
  secret_string = random_password.random_password.result
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "pecs_basm_prod_secret_access_key" {
  #checkov:skip=CKV_AWS_149
  name = "pecs_basm_prod_secret_access_key"
  tags = merge(
    local.tags,
    {
      Name = "pecs_basm_prod_secret_access_key"
    },
  )
}
resource "aws_secretsmanager_secret_version" "pecs_basm_prod_secret_access_key" {
  secret_id     = aws_secretsmanager_secret.pecs_basm_prod_secret_access_key.id
  secret_string = random_password.random_password.result
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "db_password" {
  #checkov:skip=CKV_AWS_149

  name = "${var.networking[0].application}-database-password"

  tags = merge(
    local.tags,
    {
      Name = "${var.networking[0].application}-db-password"
    },
  )
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.random_password.result
}

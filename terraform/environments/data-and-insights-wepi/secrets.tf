#### This file can be used to store secrets specific to the member account ####

# Redshift admin password secret
resource "aws_secretsmanager_secret" "wepi_redshift_admin_secret" {
  name       = "redshift-wepi-${local.environment}-admin-secret"
  kms_key_id = aws_kms_key.wepi_kms_cmk.id

  tags = merge(
    local.tags,
    {
      Name = "redshift-wepi-${local.environment}-admin-secret"
    },
  )
}

resource "random_password" "wepi_redshift_admin_pw" {
  length  = 32
  special = true

  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
}

resource "aws_secretsmanager_secret_version" "wepi_redshift_admin_pw" {
  secret_id     = aws_secretsmanager_secret.wepi_redshift_admin_secret.id
  secret_string = random_password.wepi_redshift_admin_pw.result
}

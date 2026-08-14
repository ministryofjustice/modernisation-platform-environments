# SOA credentials stored as key-value pairs. Real values are populated manually

resource "aws_secretsmanager_secret" "soa" {
  name        = local.component_name
  description = "Application secrets for ${local.component_name}"
}

resource "aws_secretsmanager_secret_version" "soa" {
  secret_id = aws_secretsmanager_secret.soa.id
  secret_string = jsonencode({
    soa_password         = ""
    trust_store_password = ""
    xxsoa_ds_password    = ""
    ebs_ds_password      = ""
    ebssms_ds_password   = ""
    pui_user_password    = ""
    ebs_user_password    = ""
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

data "aws_secretsmanager_secret_version" "soa" {
  secret_id = aws_secretsmanager_secret.soa.id
}

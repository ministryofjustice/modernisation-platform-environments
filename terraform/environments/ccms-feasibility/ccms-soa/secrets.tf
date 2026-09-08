# SOA credentials stored as key-value pairs. Real values are populated manually

resource "aws_secretsmanager_secret" "soa" {
  name        = local.component_name
  description = "Application secrets for ${local.component_name}"
}

resource "aws_secretsmanager_secret_version" "soa" {
  secret_id = aws_secretsmanager_secret.soa.id
  secret_string = jsonencode({
    admin_server_password                 = ""
    soa_rds_admin_user_password           = ""
    soa_rds_all_ccmssoa_schema_password   = ""
    edrms_xxsoa_user_password             = ""
    ccms_apps_user_password               = ""
    cwa_apps_user_password                = ""
    soa_realm_pui_user_password           = ""
    soa_realm_apply_user_password         = ""
    soa_realm_caab_user_password          = ""
    soa_realm_ebs_soa_super_user_password = ""
    keystorePassword                      = ""
    truststorePassword                    = ""
    extra_java_properties                 = ""
    slack_channel_webhook                 = ""
    admin_ebs_ds_url                      = ""
    admin_ebs_ds_username                 = ""
    admin_ebssms_ds_url                   = ""
    admin_ebssms_ds_username              = ""
    admin_ebs_user_username               = ""
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

data "aws_secretsmanager_secret_version" "soa" {
  secret_id = aws_secretsmanager_secret.soa.id
}

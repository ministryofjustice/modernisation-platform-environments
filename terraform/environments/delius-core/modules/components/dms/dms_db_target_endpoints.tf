# In client environments the dms_user_target_endpoint.write_database must be defined
# The endpoint for user (USER_ and PROBATION_AREA_USER) is the Delius primary database.
resource "aws_dms_endpoint" "dms_user_target_endpoint_db" {
  #checkov:skip=CKV_AWS_296
  count                       = try(var.dms_config.user_target_endpoint.write_database, null) == null ? 0 : 1
  database_name               = var.dms_config.user_target_endpoint.write_database
  endpoint_id                 = "${var.env_name}-user-data-to-${lower(var.dms_config.user_target_endpoint.write_database)}"
  endpoint_type               = "target"
  engine_name                 = "oracle"
  username                    = local.dms_audit_username
  password                    = join(",", [jsondecode(data.aws_secretsmanager_secret_version.delius_core_application_passwords.secret_string)[local.dms_audit_username], jsondecode(data.aws_secretsmanager_secret_version.delius_core_application_passwords.secret_string)[local.dms_audit_username]])
  server_name                 = join(".", [var.oracle_db_server_names["primarydb"], var.account_config.route53_inner_zone.name])
  port                        = local.db_tcps_port
  extra_connection_attributes = "UseDirectPathFullLoad=false;ArchivedLogDestId=1;AdditionalArchivedLogDestId=32;asm_server=${join(".", [var.oracle_db_server_names["primarydb"], var.account_config.route53_inner_zone.name])}:${local.db_tcps_port}/+ASM;asm_user=${local.dms_audit_username};UseBFile=true;UseLogminerReader=false;"
  # We initially use an empty wallet for encryption - a populated wallet will be added by DMS configuration
  ssl_mode        = "verify-ca"
  certificate_arn = aws_dms_certificate.empty_oracle_wallet.certificate_arn
  # Ignore subsequent replacement with a valid wallet
  lifecycle {
    ignore_changes = [certificate_arn]
  }
  depends_on = [aws_dms_certificate.empty_oracle_wallet]
}

# In repository environments the end point for audit (AUDITED_INTERACTION, BUSINESS_INTERACTION) is the Delius primary database.
resource "aws_dms_endpoint" "dms_audit_target_endpoint_db" {
  #checkov:skip=CKV_AWS_296
  count                       = try(var.dms_config.audit_target_endpoint.write_database, null) == null ? 0 : 1
  database_name               = var.dms_config.audit_target_endpoint.write_database
  endpoint_id                 = "${var.env_name}-audit-data-to-${lower(var.dms_config.audit_target_endpoint.write_database)}"
  endpoint_type               = "target"
  engine_name                 = "oracle"
  username                    = local.dms_audit_username
  password                    = join(",", [jsondecode(data.aws_secretsmanager_secret_version.delius_core_application_passwords.secret_string)[local.dms_audit_username], jsondecode(data.aws_secretsmanager_secret_version.delius_core_application_passwords.secret_string)[local.dms_audit_username]])
  server_name                 = join(".", [var.oracle_db_server_names["primarydb"], var.account_config.route53_inner_zone.name])
  port                        = local.db_tcps_port
  extra_connection_attributes = "UseDirectPathFullLoad=false;ArchivedLogDestId=1;AdditionalArchivedLogDestId=32;asm_server=${join(".", [var.oracle_db_server_names["primarydb"], var.account_config.route53_inner_zone.name])}:${local.db_tcps_port}/+ASM;asm_user=${local.dms_audit_username};UseBFile=true;UseLogminerReader=false;"
  # We initially use an empty wallet for encryption - a populated wallet will be added by DMS configuration
  ssl_mode        = "verify-ca"
  certificate_arn = aws_dms_certificate.empty_oracle_wallet.certificate_arn
  # Ignore subsequent replacement with a valid wallet
  lifecycle {
    ignore_changes = [certificate_arn]
  }
  depends_on = [aws_dms_certificate.empty_oracle_wallet]
}

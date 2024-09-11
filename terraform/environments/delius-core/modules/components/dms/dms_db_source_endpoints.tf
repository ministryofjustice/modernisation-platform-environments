# We must have both a source and target endpoint for each environment involved in Audit Preservation
# since there is a flow of Audit data in one directory and User data in the other direction (since
# user IDs must be kept consistent)

# In client environments the dms_audit_source_endpoint.read_database must be defined
# The endpoint for audit (AUDITED_INTERACTION) is the Delius database.
resource "aws_dms_endpoint" "dms_audit_source_endpoint_db" {
   count                           = try(var.dms_config.audit_source_endpoint.read_database, null) == null ? 0 : 1
   database_name                   = var.dms_config.audit_source_endpoint.read_database
   endpoint_id                     = "audit-data-from-${lower(var.dms_config.audit_source_endpoint.read_database)}"
   endpoint_type                   = "source"
   engine_name                     = "oracle"
   username                        = local.dms_audit_username
   password                        = join(",",[jsondecode(data.aws_secretsmanager_secret_version.delius_core_application_passwords.secret_string)[local.dms_audit_username],jsondecode(data.aws_secretsmanager_secret_version.delius_core_application_passwords.secret_string)[local.dms_audit_username]])
   server_name                     = join(".",[var.oracle_db_server_names[var.dms_config.audit_source_endpoint.read_host],var.account_config.route53_inner_zone_info.name])
   port                            = local.oracle_port
   extra_connection_attributes     = "ArchivedLogDestId=1;AdditionalArchivedLogDestId=32;asm_server=${join(".",[var.oracle_db_server_names[var.dms_config.audit_source_endpoint.read_host],var.account_config.route53_inner_zone_info.name])}:${local.oracle_port}/+ASM;asm_user=${local.dms_audit_username};UseBFile=true;UseLogminerReader=false;"
}

# In repository environments the dms_user_source_endpoint.read_database must be defined
# The endpoint for user (USER_) is the Delius database.
resource "aws_dms_endpoint" "dms_user_source_endpoint_db" {
   count                           = try(var.dms_config.user_source_endpoint.read_database, null) == null ? 0 : 1
   database_name                   = var.dms_config.user_source_endpoint.read_database
   endpoint_id                     = "user-data-from-${lower(var.dms_config.user_source_endpoint.read_database)}"
   endpoint_type                   = "source"
   engine_name                     = "oracle"
   username                        = local.dms_audit_username
   password                        = join(",",[jsondecode(data.aws_secretsmanager_secret_version.delius_core_application_passwords.secret_string)[local.dms_audit_username],jsondecode(data.aws_secretsmanager_secret_version.delius_core_application_passwords.secret_string)[local.dms_audit_username]])
   server_name                     = join(".",[var.oracle_db_server_names[var.dms_config.user_source_endpoint.read_host],var.account_config.route53_inner_zone_info.name])
   port                            = local.oracle_port
   extra_connection_attributes     = "ArchivedLogDestId=1;AdditionalArchivedLogDestId=32;asm_server=${join(".",[var.oracle_db_server_names[var.dms_config.user_source_endpoint.read_host],var.account_config.route53_inner_zone_info.name])}:1521/+ASM;asm_user=${local.dms_audit_username};UseBFile=true;UseLogminerReader=false;"
}

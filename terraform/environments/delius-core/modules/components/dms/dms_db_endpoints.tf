# We must have both a source and target endpoint for each environment involved in Audit Preservation
# since there is a flow of Audit data in one directory and User data in the other direction (since
# user IDs must be kept consistent)

# In client environments the dms_audit_source_endpoint.read_database must be defined
# The endpoint for audit (AUDITED_INTERACTION) is the Delius database.
resource "aws_dms_endpoint" "dms_audit_source_endpoint_db" {
   count                           = var.dms_audit_source_endpoint.read_database == null ? 0 : 1
   database_name                   = var.dms_audit_source_endpoint.read_database
   endpoint_id                     = "audit-data-from-${var.dms_audit_source_endpoint.read_database}"
   endpoint_type                   = "source"
   engine_name                     = "oracle"
   secrets_manager_access_role_arn = "arn:aws:iam::${local.delius_account_id}:role/DMSSecretsManagerAccessRole"
   secrets_manager_arn             = aws_secretsmanager_secret.dms_audit_source_endpoint_db.arn
   extra_connection_attributes     = "ArchivedLogDestId=1;AdditionalArchivedLogDestId=32;asm_server=${var.oracle_db_server_names[var.dms_audit_source_endpoint.read_host]}/+ASM;asm_user=delius_audit_dms_pool;UseBFile=true;UseLogminerReader=false;"
}

# In repository environments the dms_user_source_endpoint.read_database must be defined
# The endpoint for user (USER_) is the Delius database.
resource "aws_dms_endpoint" "dms_user_source_endpoint_db" {
   count                           = var.dms_user_source_endpoint.read_database == null ? 0 : 1
   database_name                   = var.dms_user_source_endpoint.read_database
   endpoint_id                     = "user-data-from-${var.dms_user_source_endpoint.read_database}"
   endpoint_type                   = "source"
   engine_name                     = "oracle"
   secrets_manager_access_role_arn = "arn:aws:iam::${local.delius_account_id}:role/DMSSecretsManagerAccessRole"
   secrets_manager_arn             = aws_secretsmanager_secret.dms_user_source_endpoint_db.arn
   extra_connection_attributes     = "ArchivedLogDestId=1;AdditionalArchivedLogDestId=32;asm_server=${var.oracle_db_server_names[var.dms_config.user_source_endpoint.read_host]}/+ASM;asm_user=delius_audit_dms_pool;UseBFile=true;UseLogminerReader=false;"
}
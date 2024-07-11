# We must have both a source and target endpoint for each environment involved in Audit Preservation
# since there is a flow of Audit data in one directory and User data in the other direction (since
# user IDs must be kept consistent)

# In client environments the dms_audit_source_endpoint.read_database must be defined
# The endpoint for audit (AUDITED_INTERACTION) is the Delius database.


# As of date of writing, the AWS_DMS_ENDPOINT resource does not support using Secrets Manager for
# ASM connectivity as Oracle-specific attributes are not available.
# A replacement resource, aws_dms_oracle_endpoint, is in development and the following should be replaced
# once that becomes available.
# In the meantime we cannot use Secrets for holding connection details since we have no place where we
# can define the ASM password.
# We are therefore restricted to using inline definition of endpoints.  NB: We assume the delius_audit_dms_pool
# password is the same for both the DB and ASM instances.
# Reference:  https://github.com/hashicorp/terraform-provider-aws/issues/23506
resource "aws_dms_endpoint" "dms_audit_source_endpoint_db" {
   count                           = try(var.dms_config.audit_source_endpoint.read_database, null) == null ? 0 : 1
   database_name                   = var.dms_config.audit_source_endpoint.read_database
   endpoint_id                     = "audit-data-from-${var.dms_config.audit_source_endpoint.read_database}"
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
   endpoint_id                     = "user-data-from-${var.dms_config.user_source_endpoint.read_database}"
   endpoint_type                   = "source"
   engine_name                     = "oracle"
   username                        = local.dms_audit_username
   password                        = join(",",[jsondecode(data.aws_secretsmanager_secret_version.delius_core_application_passwords.secret_string)[local.dms_audit_username],jsondecode(data.aws_secretsmanager_secret_version.delius_core_application_passwords.secret_string)[local.dms_audit_username]])
   server_name                     = join(".",[var.oracle_db_server_names[var.dms_config.audit_source_endpoint.read_host],var.account_config.route53_inner_zone_info.name])
   extra_connection_attributes     = "ArchivedLogDestId=1;AdditionalArchivedLogDestId=32;asm_server=${join(".",[var.oracle_db_server_names[var.dms_config.user_source_endpoint.read_host],var.account_config.route53_inner_zone_info.name])}:1521/+ASM;asm_user=${local.dms_audit_username};UseBFile=true;UseLogminerReader=false;"
}

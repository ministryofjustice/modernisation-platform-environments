# We must have both a source and target endpoint for each environment involved in Audit Preservation
# since there is a flow of Audit data in one directory and User data in the other direction (since
# user IDs must be kept consistent)
#
#  The password is a comma-separated list of <DMS User Password>,<ASM User Password>
#  Here we always use the same password for both users.
#
data "http" "ansible_all_groupvars_file" {
  url = format("https://raw.githubusercontent.com/ministryofjustice/modernisation-platform-configuration-management/main/ansible/group_vars/environment_name_%s_%s_all.yml",replace(terraform.workspace,"-","_"),var.env_name)
}

data "http" "ansible_primarydb_groupvars_file" {
  url = format("https://raw.githubusercontent.com/ministryofjustice/modernisation-platform-configuration-management/main/ansible/group_vars/environment_name_%s_%s_delius_primarydb.yml",replace(terraform.workspace,"-","_"),var.env_name)
}

data "http" "ansible_standbydb1_groupvars_file" {
  url = format("https://raw.githubusercontent.com/ministryofjustice/modernisation-platform-configuration-management/main/ansible/group_vars/environment_name_%s_%s_delius_standbydb1.yml",replace(terraform.workspace,"-","_"),var.env_name)
}

data "http" "ansible_standbydb2_groupvars_file" {
  url = format("https://raw.githubusercontent.com/ministryofjustice/modernisation-platform-configuration-management/main/ansible/group_vars/environment_name_%s_%s_delius_standbydb2.yml",replace(terraform.workspace,"-","_"),var.env_name)
}

locals {
  audited_interaction_repository = try("${yamldecode(data.http.ansible_all_groupvars_file.response_body)["audited_interaction_repository"]}","none")
  primarydb_database_name = "${yamldecode(data.http.ansible_primarydb_groupvars_file.response_body)["database_primary_sid"]}"
  standbydb1_database_name = try("${yamldecode(data.http.ansible_standbydb1_groupvars_file.response_body)["database_standby_sid"]}","none")
  standbydb1_active_data_guard = try("${yamldecode(data.http.ansible_standbydb1_groupvars_file.response_body)["active_data_guard"]}","none")
  standbydb2_database_name = try("${yamldecode(data.http.ansible_standbydb2_groupvars_file.response_body)["database_standby_sid"]}","none")
  standbydb2_active_data_guard = try("${yamldecode(data.http.ansible_standbydb2_groupvars_file.response_body)["active_data_guard"]}","none")
  read_target = local.standbydb2_active_data_guard == "true" ? "standbydb2" : (local.standbydb1_active_data_guard == "true" ? "standbydb1" : "primarydb")
}

# resource "aws_dms_endpoint" "source_endpoint" {
#    database_name                   = local.standbydb2_database_name
#    endpoint_id                     = "${local.audited_interaction_repository == "none" ? "user-data-from" : "audit-data-from"}-${env.env_name}"
#    endpoint_type                   = "source"
#    engine_name                     = "oracle"
#    secrets_manager_access_role_arn = "arn:aws:iam::${local.delius_account_id}:role/DMSSecretsManagerAccessRole"
#    secrets_manager_arn             = aws_secretsmanager_secret.dms_audit_endpoint_source.arn


# resource "aws_dms_endpoint" "source_endpoint" {
#   database_name               = local.standbydb2_database_name
#   endpoint_id                 = "${lookup(each.value.outputs.dms_endpoint_details,"target_environment","unset") == "unset" ? "user-data-from" : "audit-data-from"}-${local.inverted_aws_account_ids[each.key]}"
#   endpoint_type               = "source"
#   engine_name                 = "oracle"
#   username                    = "delius_audit_dms_pool"
#   password                    = "${lookup(local.password_map,local.inverted_aws_account_ids[each.key],"password")},${lookup(local.password_map,local.inverted_aws_account_ids[each.key],"password")}"
#   server_name                 = each.value.outputs.dms_endpoint_details.database_server_for_reads
#   port                        = each.value.outputs.dms_endpoint_details.database_port_for_reads
#   extra_connection_attributes = "ArchivedLogDestId=1;AdditionalArchivedLogDestId=32;asm_server=${each.value.outputs.dms_endpoint_details.database_server_for_reads}/+ASM;asm_user=delius_audit_dms_pool;UseBFile=true;UseLogminerReader=false;"
#   # We initially use an empty wallet for encryption - a populated wallet will be added by DMS configuration
#   ssl_mode                    = "verify-ca"
#   certificate_arn             = aws_dms_certificate.empty_oracle_wallet.certificate_arn
#   # Ignore subsequent replacement with a valid wallet
#   lifecycle {
#     ignore_changes = [certificate_arn]
#   }

#   depends_on = [aws_dms_replication_instance.audited_interaction_replication,local_file.remote_providers]
# }
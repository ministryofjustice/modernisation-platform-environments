resource "aws_dms_replication_task" "audited_interaction_outbound_replication" {
  count               = try(var.dms_config.audit_source_endpoint.read_database, null) == null ? 0 : 1
  replication_task_id = "${var.env_name}-audited-interaction-replication-task-for-${lower(var.dms_config.audit_source_endpoint.read_database)}"
  migration_type      = "cdc" 

  # Even though we have the option to read from a standby database, we always record the name of the *primary*
  # database against the CLIENT_DB column when writing to the Staging table.   This provides consistency
  # when querying the data as we do not need to know whether the primary or standby was used.
  
  # We do not fail a replication task but keep retrying every 1800 seconds (RecoverableErrorStopRetryAfterThrottlingMax=false)
  # This allows us to resume after downtime on an endpoint but note that this means that errors will not be raised
  # and must be monitored independently.
  #
  table_mappings      = templatefile("templates/audited_interaction_table_mapping.tmpl",{
                           client_database = local.audit_source_primary
                        })

  replication_task_settings = file("files/audited_interaction_settings.json")

  source_endpoint_arn      = aws_dms_endpoint.dms_audit_source_endpoint_db[0].endpoint_arn
  target_endpoint_arn      = aws_dms_s3_endpoint.dms_audit_target_endpoint_s3[0].endpoint_arn
  replication_instance_arn = aws_dms_replication_instance.dms_replication_instance.replication_instance_arn

  tags = merge(
    var.tags,
    {
      "name" = "Audit Replication from ${var.env_name} to ${var.dms_config.audit_target_endpoint.write_environment}"
    },
    {
      "audit-client-environment" = "${var.env_name}"
    },
    {
      "audit-repository-environment" = "${var.dms_config.audit_target_endpoint.write_environment}"
    },
  )

}
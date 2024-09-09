# User inbound replication only happens in client environments.
resource "aws_dms_replication_task" "user_inbound_replication" {
  count               = try(var.dms_config.user_target_endpoint.write_database, null) == null ? 0 : 1
  replication_task_id = "${var.env_name}-user-inbound-replication-task-from-${var.dms_config.audit_target_endpoint.write_environment}"
  migration_type      = "cdc" 

  table_mappings            = file("files/user_inbound_table_mapping.json")
  replication_task_settings = file("files/user_inbound_settings.json")

  source_endpoint_arn      = aws_dms_s3_endpoint.dms_user_source_endpoint_s3[0].endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.dms_user_target_endpoint_db[0].endpoint_arn
  replication_instance_arn = aws_dms_replication_instance.dms_replication_instance.replication_instance_arn

  tags = merge(
    var.tags,
    {
      "name" = "User Replication from ${var.dms_config.audit_target_endpoint.write_environment} to ${var.env_name}"
    },
    {
      "audit-client-environment" = "${var.env_name}"
    },
    {
      "audit-repository-environment" = "${var.dms_config.audit_target_endpoint.write_environment}"
    },
  )

}

# Business Interaction inbound replication only happens in the repository environments.
# There is one replication task for each for the feeder client environments.
resource "aws_dms_replication_task" "business_interaction_inbound_replication" {
  for_each            = toset(try(local.dms_s3_cross_account_client_environments[var.env_name],[]))
  replication_task_id = "${var.env_name}-business-interaction-inbound-replication-task-from-${each.value}"
  migration_type      = "full-load-and-cdc" 

  table_mappings            = file("files/business_interaction_inbound_table_mapping.json")
  replication_task_settings = file("files/business_interaction_inbound_settings.json")
 
  source_endpoint_arn      = aws_dms_s3_endpoint.dms_audit_source_endpoint_s3[each.value].endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.dms_audit_target_endpoint_db[0].endpoint_arn
  replication_instance_arn = aws_dms_replication_instance.dms_replication_instance.replication_instance_arn

  tags = merge(
    var.tags,
    {
      "name" = "Business Interaction Replication from ${each.value} to ${var.env_name}"
    },
    {
      "audit-client-environment" = "${each.value}"
    },
    {
      "audit-repository-environment" = "${var.env_name}"
    },
  )

}


# Audited Interaction inbound replication only happens in the repository environments.
# There is one replication task for each for the feeder client environments.
resource "aws_dms_replication_task" "audited_interaction_inbound_replication" {
  for_each            = toset(try(local.dms_s3_cross_account_client_environments[var.env_name],[]))
  replication_task_id = "${var.env_name}-audited-interaction-inbound-replication-task-from-${each.value}"
  migration_type      = "cdc" 

  table_mappings            = file("files/audited_interaction_inbound_table_mapping.json")
  replication_task_settings = file("files/audited_interaction_inbound_settings.json")
 
  source_endpoint_arn      = aws_dms_s3_endpoint.dms_audit_source_endpoint_s3[each.value].endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.dms_audit_target_endpoint_db[0].endpoint_arn
  replication_instance_arn = aws_dms_replication_instance.dms_replication_instance.replication_instance_arn

  tags = merge(
    var.tags,
    {
      "name" = "Audited Interaction Replication from ${each.value} to ${var.env_name}"
    },
    {
      "audit-client-environment" = "${each.value}"
    },
    {
      "audit-repository-environment" = "${var.env_name}"
    },
  )

}

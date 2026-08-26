# User inbound replication only happens in CLIENT environments.  This reads USER_ data from the local S3
# bucket (source endpoint) into the local Delius database (target endpoint).
# We only want to replication changes to the user data so this is a CDC task.
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
      "audit-client-environment" = var.env_name
    },
    {
      "audit-repository-environment" = var.dms_config.audit_target_endpoint.write_environment
    },
  )

}

# Business Interaction inbound replication only happens in the REPOSITORY environments.
# There is one replication task for each for the feeder client environments.
# This reads BUSINESS_INTERACTION data from the local S3 bucket (source endpoint) to the local
# Delius database (target endpoint).   Each client database has a different folder in S3.
# Since BUSINESS_INTERACTION is a reference table we start replication with a FULL LOAD.
resource "aws_dms_replication_task" "business_interaction_inbound_replication" {
  for_each            = local.client_account_map
  replication_task_id = "${var.env_name}-business-interaction-inbound-replication-task-from-${each.key}"
  migration_type      = "full-load-and-cdc"

  table_mappings            = file("files/business_interaction_inbound_table_mapping.json")
  replication_task_settings = file("files/business_interaction_inbound_settings.json")

  source_endpoint_arn      = aws_dms_s3_endpoint.dms_audit_source_endpoint_s3[each.key].endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.dms_audit_target_endpoint_db[0].endpoint_arn
  replication_instance_arn = aws_dms_replication_instance.dms_replication_instance.replication_instance_arn

  tags = merge(
    var.tags,
    {
      "name" = "Business Interaction Replication from ${each.key} to ${var.env_name}"
    },
    {
      "audit-client-environment" = each.key
    },
    {
      "audit-repository-environment" = var.env_name
    },
  )

}


# Audited Interaction inbound replication only happens in the REPOSITORY environments.
# There is one replication task for each for the feeder client environments.
# This reads AUDITED_INTERACTION data from the local S3 bucket (source endpoint) to the local
# Delius database (target endpoint).   Each client database has a different folder in S3.
# We only want to capture new audit records so this is a CDC task.
resource "aws_dms_replication_task" "audited_interaction_inbound_replication" {
  for_each            = local.client_account_map
  replication_task_id = "${var.env_name}-audited-interaction-inbound-replication-task-from-${each.key}"
  migration_type      = "cdc"

  table_mappings            = file("files/audited_interaction_inbound_table_mapping.json")
  replication_task_settings = file("files/audited_interaction_inbound_settings.json")

  source_endpoint_arn      = aws_dms_s3_endpoint.dms_audit_source_endpoint_s3[each.key].endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.dms_audit_target_endpoint_db[0].endpoint_arn
  replication_instance_arn = aws_dms_replication_instance.dms_replication_instance.replication_instance_arn

  tags = merge(
    var.tags,
    {
      "name" = "Audited Interaction Replication from ${each.key} to ${var.env_name}"
    },
    {
      "audit-client-environment" = each.key
    },
    {
      "audit-repository-environment" = var.env_name
    },
  )

}

# Audited Interaction Checksum inbound replication only happens in the REPOSITORY environments.
# There is one replication task for each for the feeder client environments.
# This reads AUDITED_INTERACTION_CHECKSUM data from the local S3 bucket (source endpoint) to the local
# Delius database (target endpoint).   Each client database has a different folder in S3.
# We only want to capture new audit records so this is a CDC task.
resource "aws_dms_replication_task" "audited_interaction_checksum_inbound_replication" {
  for_each            = local.client_account_map
  replication_task_id = "${var.env_name}-audited-interaction-checksum-inbound-replication-task-from-${each.key}"
  migration_type      = "cdc"

  table_mappings            = file("files/audited_interaction_checksum_inbound_table_mapping.json")
  replication_task_settings = file("files/audited_interaction_checksum_inbound_settings.json")

  source_endpoint_arn      = aws_dms_s3_endpoint.dms_audit_source_endpoint_s3[each.key].endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.dms_audit_target_endpoint_db[0].endpoint_arn
  replication_instance_arn = aws_dms_replication_instance.dms_replication_instance.replication_instance_arn

  tags = merge(
    var.tags,
    {
      "name" = "Audited Interaction Checksum Replication from ${each.key} to ${var.env_name}"
    },
    {
      "audit-client-environment" = each.key
    },
    {
      "audit-repository-environment" = var.env_name
    },
  )

}

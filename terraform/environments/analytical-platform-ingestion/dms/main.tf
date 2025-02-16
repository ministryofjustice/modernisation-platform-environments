resource "aws_dms_s3_endpoint" "target" {
  # count = var.setup_dms_endpoints && var.setup_dms_s3_endpoint ? 1 : 0

  endpoint_id                      = "${local.project_id}-dms-${local.short_name}-s3-target-endpoint"
  endpoint_type                    = "target"
  bucket_name                      = "mojap-raw-hist"
  service_access_role_arn          = module.production_replication_cica_dms_iam_role.arn
  data_format                      = "parquet"
  cdc_path                         = "cdc"
  timestamp_column_name            = "_timestamp"
  parquet_timestamp_in_millisecond = false
  include_op_for_full_load         = true
  max_file_size          = 120000
  cdc_max_batch_interval = 10

 #  tags = merge(
 #    var.tags,
 #    {
 #      Resource_Type = "DMS Target Endpoint"
 # })
}

# convert these vars in source to secret values

resource "aws_dms_endpoint" "source" {
  database_name = "database-string!87659!"
  #database_name = "${local.db_creds_source.[source_database_name]}"
  #endpoint_id   = "${local.db_creds_source.[endpoint_id]}"
  endpoint_id   = "endpoint-id-string!87659!"
  endpoint_type = "source"
  engine_name   = "oracle"
  username      = "username-string!87659!"
  #username      = "${local.db_creds_source.[source_username]}"
  password      = "password-string!87659!"
  #password      = "${local.db_creds_source.[source_password]}"
  # kms_key_arn                 = "arn:aws:kms:us-east-1:123456789012:key/ 12345678-1234-1234-1234-123456789012"
  kms_key_arn   = module.dms_kms_source_cmk.key_arn
  port          = 1521
  server_name   = "server-name-string!87659!"
  #server_name   = "${local.db_creds_source.[source_servername]}"
  ssl_mode      = "none"
}

# resource "aws_dms_replication_task" "dms-replication" {
#   #count = var.setup_dms_instance && var.enable_replication_task ? 1 : 0
#
#   migration_type            = var.migration_type
#   replication_instance_arn  = aws_dms_replication_instance.dms[0].replication_instance_arn
#   replication_task_id       = "${var.project_id}-dms-task-${var.short_name}-${local.dms_source_name}-${local
#   .dms_target_name}"
#   source_endpoint_arn       = aws_dms_endpoint.source[0].endpoint_arn
#   target_endpoint_arn       = aws_dms_s3_endpoint.s3_target_endpoint[0].endpoint_arn
#   table_mappings            = data.template_file.table-mappings.rendered
#   replication_task_settings = file("${path.module}/config/${var.short_name}-replication-settings.json")
#
#   #lifecycle {
#   #  ignore_changes = [replication_task_settings]
#   #}
#
#   depends_on = [
#     aws_dms_replication_instance.dms,
#     aws_dms_endpoint.source,
#     aws_dms_s3_endpoint.target
#   ]
# }
#
# resource "aws_dms_replication_task" "migration-task" {
#   migration_type           = "full-load"
#   replication_instance_arn = aws_dms_replication_instance.dms.replication_instance_arn
#   replication_task_id       = "cica-dms-replication-task"
#   # to be replaced in platform_locals
#   source_endpoint_arn      = aws_dms_endpoint.source.endpoint_arn
#   # to be replaced in platform_locals
#   target_endpoint_arn      = aws_dms_s3_endpoint.target.endpoint_arn
#   start_replication_task   = true
#
#   replication_task_settings = jsonencode({
#     TargetMetadata = {
#       FullLobMode  = true,
#       LobChunkSize = 64
#     },
#     FullLoadSettings = {
#       TargetTablePrepMode = "DO_NOTHING"
#     },
#     ControlTablesSettings = {
#       historyTimeslotInMinutes = 5
#     },
#     ErrorBehavior = {
#       DataErrorPolicy            = "LOG_ERROR"
#       ApplyErrorDeletePolicy     = "LOG_ERROR"
#       ApplyErrorInsertPolicy     = "LOG_ERROR"
#       ApplyErrorUpdatePolicy     = "LOG_ERROR"
#       ApplyErrorEscalationCount  = 0
#       ApplyErrorEscalationPolicy = "LOG_ERROR"
#     }
#   })
#
#   table_mappings = jsonencode({
#     rules = [
#       {
#         "rule-type" = "selection"
#         "rule-id"   = "1"
#         "rule-name" = "1"
#         "object-locator" = {
#           "schema-name" = "dbo"
#           "table-name"  = "%"
#         }
#         "rule-action" = "include"
#       }
#     ]
#   })
#
# }



# Create a new DMS replication instance
resource "aws_dms_replication_instance" "dms" {
  #checkov:skip=CKV_AWS_222: "Ensure DMS replication instance gets all minor upgrade automatically"
  #checkov:skip=CKV_AWS_212: "Ensure DMS replication instance is encrypted by KMS using a customer managed Key (CMK)"
  # count = var.setup_dms_instance ? 1 : 0

  allocated_storage             = 200
  apply_immediately             = true
  auto_minor_version_upgrade    = false
  availability_zone             = "eu-west-2a"
  engine_version                = "3.5.4"
  multi_az                      = true
  preferred_maintenance_window  = "sun:10:30-sun:14:30"
  publicly_accessible           = false
  replication_instance_class    = "dms.t2.large"
  replication_instance_id       = "${var.project_id}-dms-${var.short_name}-replication-instance"
  kms_key_arn                   = module.dms_kms_source_cmk.key_arn
  replication_subnet_group_id   = aws_dms_replication_subnet_group.dms[0].id
  vpc_security_group_ids        = aws_security_group.dms_sec_group[*].id

  tags = var.tags

  timeouts {
    create = "1h"
    update = "1h"
    delete = "1h"
  }

  depends_on = [
    #var.vpc_role_dependency,
    aws_dms_replication_subnet_group.dms,
    aws_security_group.dms_sec_group
  ]
}

data "template_file" "table-mappings" {
  template = file("${path.module}/config/${var.short_name}-table-mappings.json.tpl")
}



# Create an endpoint for the source database
#resource "aws_dms_endpoint" "source" {
#  #checkov:skip=CKV2_AWS_49: "Ensure AWS Database Migration Service endpoints have SSL configured - Will resolve through Spike"
#  #checkov:skip=CKV_AWS_296: "Ensure DMS endpoint uses Customer Managed Key (CMK).TO DO Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083
#
#
#  count = var.setup_dms_instance ? 1 : 0
#
#  database_name = var.source_db_name
#  endpoint_id   = "${var.project_id}-dms-${var.short_name}-${var.dms_source_name}-source"
#  endpoint_type = "source"
#  engine_name   = var.source_engine_name
#  password      = var.source_app_password
#  port          = var.source_db_port
#  server_name   = var.source_address
#  ssl_mode      = "none"
#  username      = var.source_app_username
#
#  extra_connection_attributes = var.extra_attributes
#
#  tags = var.tags
#
#  depends_on = [
#    aws_dms_replication_instance.dms
#  ]
#}


# Create a subnet group using existing VPC subnets
resource "aws_dms_replication_subnet_group" "dms" {
  # count = var.setup_dms_instance ? 1 : 0

  replication_subnet_group_description = "DMS replication subnet group"
  replication_subnet_group_id          = "${var.project_id}-dms-${var.short_name}-${local.dms_source_name}-${local
  .dms_target_name}-subnet-group"


  # subnet_ids = concat([for subnet in module.isolated_vpc.private_subnets : subnet.id], [
  #   for
  #   subnet in module.isolated_vpc.private_subnets : subnet.id
  # ])
}

# Security Groups
resource "aws_security_group" "dms_sec_group" {

  #checkov:skip=CKV_AWS_23: "Ensure every security group and rule has a description"
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  # count = var.setup_dms_instance ? 1 : 0

  name   = "${var.project_id}-dms-${var.short_name}-${local.dms_source_name}-${local.dms_target_name}-security-group"

  vpc_id = data.aws_vpc.shared.id



  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"

    cidr_blocks = ["10.202.0.0/20"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

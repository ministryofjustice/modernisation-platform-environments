resource "aws_dms_endpoint" "target" {
  database_name = var.target_database_name
  endpoint_id   = var.target_endpoint_id
  endpoint_type = "target"
  engine_name   = "sqlserver"
  username      = var.target_username
  password      = var.target_password
  port          = 1433
  server_name   = var.target_server_name
  ssl_mode      = "none"
}

resource "aws_dms_endpoint" "source" {
  database_name = var.source_database_name
  endpoint_id   = var.source_endpoint_id
  endpoint_type = "source"
  engine_name   = "sqlserver"
  password      = var.source_password
  port          = 1433
  server_name   = var.source_server_name
  ssl_mode      = "none"

  username = var.source_username
}

resource "aws_dms_replication_task" "migration-task" {
  migration_type           = "full-load"
  replication_instance_arn = var.replication_instance_arn
  replication_task_id      = var.replication_task_id
  source_endpoint_arn      = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.target.endpoint_arn
  start_replication_task   = false

  replication_task_settings = jsonencode({
    TargetMetadata = {
      FullLobMode  = true,
      LobChunkSize = 64
    },
    FullLoadSettings = {
      TargetTablePrepMode = "DROP_TABLES_ON_TARGET"
    },
    ControlTablesSettings = {
      historyTimeslotInMinutes = 5
    },
    ErrorBehavior = {
      DataErrorPolicy            = "LOG_ERROR"
      ApplyErrorDeletePolicy     = "LOG_ERROR"
      ApplyErrorInsertPolicy     = "LOG_ERROR"
      ApplyErrorUpdatePolicy     = "LOG_ERROR"
      ApplyErrorEscalationCount  = 0
      ApplyErrorEscalationPolicy = "LOG_ERROR"
    }
  })

  table_mappings = jsonencode({
    rules = [
      {
        "rule-type" = "selection"
        "rule-id"   = "1"
        "rule-name" = "1"
        "object-locator" = {
          "schema-name" = "dbo"
          "table-name"  = "%"
        }
        "rule-action" = "include"
      }
    ]
  })

}
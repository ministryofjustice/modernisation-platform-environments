

module "dms_rds_spike" {
  source = "../modules/dms_spike"

  # Instance Configuration
  dms_instance_id    = "mysql-rds-spike-${var.local.environment}"
  rds_instance_arn   = data.aws_db_instance.database_2022.arn
  dms_subnet_id      = tolist(data.aws_db_subnet_group.db.subnet_ids)
  dms_security_group = data.aws_security_group.dms_ri_security_group.id

  # Connection details
  engine_name = "sqlserver"
  username    = data.aws_db_instance.database_2022.username
  password    = data.aws_db_instance.database_2022.password
  server_name = split(":", data.aws_db_instance.database_2022.endpoint)[0]
  port        = data.aws_db_instance.database_2022.port

  # RDS Data Source and target details
  s3_bucket_name  = "emds-${var.local.environment}-data-20240917144025201600000001"
  table_mappings = file("${path.module}/table_mappings/lcm_archive_2019.json")
  database_name  = "lcm_archive_2019"
}
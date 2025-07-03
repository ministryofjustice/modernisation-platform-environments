

module "dms_rds_spike" {
  source = "./modules/dms_spike"

  # Instance Configuration
  dms_instance_id    = "mysql-rds-spike-${local.environment}"
  rds_instance_arn   = aws_db_instance.database_2022.arn
  dms_subnet_id      = tolist(aws_db_subnet_group.db.subnet_ids)
  dms_security_group = aws_security_group.dms_ri_security_group[0].id

  # Connection details
  engine_name = "sqlserver"
  username    = aws_db_instance.database_2022.username
  password    = aws_db_instance.database_2022.password
  server_name = split(":", data.aws_db_instance.database_2022.endpoint)[0]
  port        = aws_db_instance.database_2022.port

  # RDS Data Source and target details
  s3_bucket_name  = "emds-${local.environment}-data-20240917144025201600000001"
  table_mappings = file("table_mappings/lcm_archive_2019.json")
  database_name  = "lcm_archive_2019"
}
module "rds" {
  source = "./modules/rds"
  application_name = local.application_name
  environment = local.environment
  tags = local.tags
  db_family = "oracle-se2-19"
  db_engine = "oracle-se2"
  db_engine_version = "19"
  db_full_engine_version = "19.0.0.0.ru-2021-10.rur-2021-10.r1"
  db_subnet_ids = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]
  db_vpc_id = data.aws_vpc.shared.id
  db_instance_class = "db.t3.small"
  db_storage_type = "gp2"
  db_storage_iops = 300
  db_backup_retention_period = 35
  db_admin_username = "admin"
}

module "dms_task" {
  source = "./modules/dms"

  for_each = toset(var.database_list)

  database_name = each.key

  # dms_vpc_id = data.aws_vpc.shared.id
  rds_db_security_group_id = aws_security_group.db.id
  rds_db_server_name = split(":", aws_db_instance.database_2022.endpoint)[0]
  rds_db_instance_port = aws_db_instance.database_2022.port
  rds_db_username = aws_db_instance.database_2022.username
  rds_db_instance_pasword = aws_db_instance.database_2022.password

  target_s3_bucket_name = data.aws_s3_bucket.existing_dms_bucket.id
  ep_service_access_role_arn = aws_iam_role.dms-endpoint-role.arn
}
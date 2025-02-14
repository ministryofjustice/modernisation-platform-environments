# DMS Source Endpoint
resource "aws_dms_endpoint" "source_endpoint" {
  endpoint_id   = "${local.db_creds_source.source_endpoint_id}"
  endpoint_type = "${local.db_creds_source.source_endpoint_type}"
  engine_name   = "${local.db_creds_source.source_engine_name}"
  username      = "${local.db_creds_source.source_username}"
  password      = "${local.db_creds_source.source_password}"
  kms_key_arn   = "${local.kms_key_id}"
  server_name   = "${local.db_creds_source.source_server_name}"
  port          = "${local.db_creds_source.source_port}"
  database_name = "${local.db_creds_source.source_database_name}"
}

# DMS S3 Target Endpoint
resource "aws_dms_s3_endpoint" "s3_target_endpoint" {
  endpoint_id             = "arn:aws:s3:::mojap-raw-hist/cica/${db_creds_source.source_database_name}/"
  endpoint_type           = "target"
  bucket_name             = "mojap-raw-hist/cica/"
  service_access_role_arn = module.production_replication_cica_dms_iam_role[0].iam_role_arn
}

resource "aws_security_group" "vpc_dms_replication_instance_group" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "vpc-dms-replication-instance-group"
  description = "allow dms replication instance access to the shared vpc on the modernisation platform"
}

# DMS Replication Subnet Group
resource "aws_dms_replication_subnet_group" "dms_replication_subnet_group" {
  replication_subnet_group_id          = "dms-replication-subnet-group"
  subnet_ids                          = data.aws_subnet.shared_private_subnets_a.id
  replication_subnet_group_description = "DMS replication subnet group"
}

# DMS Replication Instance
resource "aws_dms_replication_instance" "replication_instance" {
  replication_instance_id     = "dms-replication-instance"
  replication_instance_class  = "dms.t2.large"
  vpc_security_group_ids      = [aws_security_group.vpc_dms_replication_instance_group.id]
  replication_subnet_group_id = "dms-replication-subnet-group"
  publicly_accessible         = false
}

# DMS Replication Task
resource "aws_dms_replication_task" "replication_task" {
  replication_task_id       = "${replace(${local.db_creds_source.source_database_name}, "_", "-")}-db-migration-task-tf"
  table_mappings            = file("${path.module}/metadata/tariff_uat")
  migration_type            = "full-load-and-cdc"
  replication_instance_arn  = aws_dms_replication_instance.replication_instance.id
  source_endpoint_arn       = aws_dms_endpoint.source_endpoint.id
  target_endpoint_arn       = aws_dms_s3_endpoint.s3_target_endpoint.id
}

# DMS Source Endpoint
resource "aws_dms_endpoint" "source_endpoint" {
  endpoint_id   = var.source_database.endpoint_id
  endpoint_type = var.source_database.endpoint_type
  engine_name   = var.source_database.engine_name
  username      = var.source_database.username
  password      = var.source_database.password
  server_name   = var.source_database.server_name
  port          = var.source_database.port
  database_name = var.source_database.database_name
}

# DMS S3 Target Endpoint
resource "aws_dms_s3_endpoint" "s3_target_endpoint" {
  endpoint_id             = var.s3_bucket
  endpoint_type           = "target"
  bucket_name             = var.s3_bucket
  service_access_role_arn = aws_iam_role.dms_vpc_role.arn
}

resource "aws_security_group" "vpc_dms_replication_instance_group" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "vpc-dms-replication-instance-group"
  description = "allow dms replication instance access to the shared vpc on the modernisation platform"
}

# DMS Replication Subnet Group
resource "aws_dms_replication_subnet_group" "dms_replication_subnet_group" {
  replication_subnet_group_id          = "dms-replication-subnet-group"
  subnet_ids                           = data.aws_subnets.shared-public.ids
  replication_subnet_group_description = "DMS replication subnet group"
}

# DMS Replication Instance
resource "aws_dms_replication_instance" "replication_instance" {
  replication_instance_id     = "dms-replication-instance"
  replication_instance_class  = var.replication_instance_class
  replication_subnet_group_id = aws_dms_replication_subnet_group.replication_subnet_group.id
  publicly_accessible         = false
}

# DMS Replication Task
resource "aws_dms_replication_task" "replication_task" {
  replication_task_id       = "${replace(var.database_name, "_", "-")}-db-migration-task-tf"
  table_mappings            = trimspace(file("${path.module}/dms_${var.database_name}_task_transformations.json"))
  migration_type            = "full-load-and-cdc"
  replication_instance_arn  = aws_dms_replication_instance.replication_instance.arn
  source_endpoint_arn       = aws_dms_endpoint.source_endpoint.arn
  target_endpoint_arn       = aws_dms_s3_endpoint.s3_target_endpoint.arn
}

resource "aws_dms_replication_instance" "rds_connection" {
    replication_instance_id = "rds-conn"
    replication_instance_class = "dms.r5.large"
    allocated_storage           = 1000
    engine_version              = "3.4.4"
    vpc_security_group_ids = [aws_security_group.db.id]
}

resource "aws_dms_replication_subnet_group" "rds_subnets" {
  replication_subnet_group_description = "RDS subnet group"
  replication_subnet_group_id          = "rds-replication-subnet-group"

  subnet_ids = aws_db_subnet_group.db.subnet_ids
}
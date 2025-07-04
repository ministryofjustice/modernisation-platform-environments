resource "aws_dms_replication_subnet_group" "dms_spike_subnet_group" {
  replication_subnet_group_description = "RDS subnet group"
  replication_subnet_group_id          = "${var.dms_instance_id}-subnet-group"
  subnet_ids                           = var.dms_subnet_id


  tags = merge(
    var.local_tags,
    {
      Resource_Type = "DMS SPIKE Replication Subnet Group",
    }
  )
}

resource "aws_dms_replication_instance" "dms_spike_instance" {
  replication_instance_id     = var.dms_instance_id
  replication_instance_class  = "dms.t3.micro"
  allocated_storage           = 5
  replication_subnet_group_id = aws_dms_replication_subnet_group.dms_spike_subnet_group.replication_subnet_group_id.vpc_security_group_ids
  vpc_security_group_ids      = [var.dms_security_group]
  publicly_accessible         = false
  multi_az                    = false
  auto_minor_version_upgrade  = false

  tags = merge(var.local_tags,
    {
      Resource_Type = "DMS SPIKE Replication  Instance",
    }
  )

}
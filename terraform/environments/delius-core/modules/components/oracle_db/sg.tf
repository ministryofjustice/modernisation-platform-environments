resource "aws_security_group" "db_ec2_instance_sg" {
  name        = format("%s-sg-delius-db-ec2-instance", var.env_name)
  description = "Controls access to db ec2 instance"
  vpc_id      = var.vpc_id
  tags = merge(var.tags,
    { Name = lower(format("%s-sg-delius-db-ec2-instance", var.env_name)) }
  )
}
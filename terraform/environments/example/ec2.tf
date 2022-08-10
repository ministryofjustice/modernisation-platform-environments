# First build the security group for the EC2
resource "aws_security_group" "example_ec2_sg" {
  name        = "example_ec2_sg"
  description = "Controls access to EC2"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-example", local.application_name, local.environment)) }
  )
}
resource "aws_security_group_rule" "ingress_traffic" {
  for_each          = local.application_data.example_ec2_sg_rules
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.example_ec2_sg.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "egress_traffic" {
  for_each                 = local.application_data.example_ec2_sg_rules
  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.example_ec2_sg.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.example_ec2_sg.id
}



#  Build EC2 "example-ec2" 
resource "aws_instance" "develop" {
  # Specify the instance type and ami to be used (this is the Amazon free tier option)
  instance_type          = local.application_data.accounts[local.environment].instance_type
  ami                    = local.application_data.accounts[local.environment].ami_image_id
  vpc_security_group_ids = [aws_security_group.example_ec2_sg.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  monitoring             = true
  ebs_optimized          = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  # Increase the volume size of the root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }
  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-example", local.application_name, local.environment)) }
  )
  depends_on = [aws_security_group.example_ec2_sg]
}

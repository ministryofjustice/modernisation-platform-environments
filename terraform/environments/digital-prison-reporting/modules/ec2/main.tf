# Build the security group for the EC2
resource "aws_security_group" "ec2_kinesis_agent" {
  name        = var.name
  description = var.description
  vpc_id      = var.vpc
  tags        = var.tags
}

resource "aws_security_group_rule" "ingress_traffic" {
  for_each          = var.ec2_sec_rules
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.ec2_kinesis_agent.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = var.cidr
}

resource "aws_security_group_rule" "egress_traffic" {
  for_each                 = var.ec2_sec_rules
  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.ec2_kinesis_agent.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.ec2_kinesis_agent.id
}

#  Build EC2 
resource "aws_instance" "develop" {
  # Specify the instance type and ami to be used (this is the Amazon free tier option)
  instance_type          = var.ec2_instance_type
  ami                    = var.ami_image_id
  vpc_security_group_ids = [aws_security_group.ec2_kinesis_agent.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  monitoring             = true
  ebs_optimized          = true

  user_data = file("./scripts/startup.sh")

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
  tags       = var.tags
  depends_on = [aws_security_group.ec2_kinesis_agent]
}
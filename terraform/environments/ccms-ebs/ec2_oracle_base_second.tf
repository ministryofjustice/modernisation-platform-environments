data "aws_ami" "oracle_base_second" {
  most_recent = true
  owners      = ["131827586825"]
  filter {
    name   = "name"
    values = [local.application_data.accounts[local.environment].orace_base_ami_name_second]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


#  Build EC2 
resource "aws_instance" "ec2_oracle_base_second" {
  # Specify the instance type and ami to be used (this is the Amazon free tier option)
  instance_type               = local.application_data.accounts[local.environment].ec2_oracle_base_instance_type
  ami                         = data.aws_ami.oracle_base_second.id
  key_name                    = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg_oracle_base.id]
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_oracle_base.name

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
    { Name = lower(format("ec2-%s-%s-OracleBase-second", local.application_name, local.environment)) }
  )
  depends_on = [aws_security_group.ec2_sg_oracle_base]
}
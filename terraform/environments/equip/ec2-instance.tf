
data "aws_ebs_default_kms_key" "current" {}

resource "aws_instance" "app_test_server" {
  ami                    = "ami-03e88be9ecff64781"
  instance_type          = "t2.medium"
  subnet_id              = data.aws_subnet.public_az_a.id
  monitoring             = true
  ebs_optimized          = true
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = data.aws_ebs_default_kms_key.current.key_arn
  }


  tags = {
    Name             = "Linux Server"
    Environment      = "Dev"
    Terrform_managed = "true"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_sample_inst"
  description = "Allow inbound traffic to Test Instance"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    cidr_blocks = ["182.71.241.211/32"]
    description = "SSH Allow from Inbound"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["182.71.241.211/32"]
  }

  tags = {
    Name = "allow_ssh_access"
  }
}

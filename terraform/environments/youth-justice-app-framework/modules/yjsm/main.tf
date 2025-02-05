resource "aws_instance" "yjsm" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3a.xlarge"  
  key_name               = "user1"       
  monitoring             = true
  ebs_optimized          = true
  iam_instance_profile   = aws_iam_instance_profile.yjsm_ec2_profile.id
  vpc_security_group_ids = [aws_security_group.yjsm_service.id]
  subnet_id              = var.subnet_id



  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }   
  
  
  root_block_device {
    encrypted             = true
    delete_on_termination = false
    volume_size           = 60
    volume_type           = "gp2"
  }
  
  tags = {
    Name = "YJSM"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  owners = ["amazon"]
}
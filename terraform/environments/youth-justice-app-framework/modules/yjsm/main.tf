resource "aws_instance" "yjsm" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3a.xlarge"  
  key_name               = "user1"       
  monitoring             = true          

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
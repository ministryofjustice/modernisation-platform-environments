resource "aws_instance" "kali_linux" {
  ami           = "ami-07c1b39b7b3d2525d"
  instance_type = "t2.micro"
  subnet_id     = module.vpc.private_subnets.0
  user_data     = <<-EOF
              #!/bin/bash
              sudo apt update && sudo apt -y install software-properties-common
              sudo wget -q -O - https://archive.kali.org/archive-key.asc | sudo apt-key add -
              sudo echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" | sudo tee /etc/apt/sources.list.d/kali.list
              sudo apt update && sudo apt -y install kali-linux-default
              EOF

  tags = {
    Name = "Terraform-Kali-Linux"
  }
}

resource "aws_security_group" "allow_https" {
  name        = "allow_https"
  description = "Allow HTTPS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
}
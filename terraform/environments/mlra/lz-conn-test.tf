locals {
  instance-userdata = <<EOF
#!/bin/bash
yum install -y httpd
systemctl start httpd
EOF
}



module "mikereidhttptest_sg" {
  source = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "mikereidhttptest-sg"
  description = "Security group for TG connectivity testing between LAA LZ & MP"
  vpc_id      = "vpc-06febffe7b87ab37f"

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = "10.200.0.0/20"
    }
  ]
}










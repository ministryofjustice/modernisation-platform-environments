locals {
  instance-userdata = <<EOF
#!/bin/bash
yum install -y httpd
systemctl start httpd
EOF
}
module "ec2_instance" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 4.0"
  name                   = "landingzone-httptest"
  ami                    = "ami-06672d07f62285d1d"
  instance_type          = "t3a.small"
  vpc_security_group_ids = [module.httptest_sg.security_group_id]
  subnet_id              = "subnet-06594eda5221bd3c9"
  user_data_base64       = base64encode(local.instance-userdata)
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.id
  tags = {
    Name        = "landingzone-httptest"
    Environment = "dev"
  }
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "SsmManagedInstanceProfile"
  role = aws_iam_role.ssm_managed_instance.name
}

resource "aws_iam_role" "ssm_managed_instance" {
  name                = "SsmManagedInstance"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  assume_role_policy  = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

module "httptest_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "~> 4.0"
  name        = "landingzone-httptest-sg"
  description = "Security group for TG connectivity testing between LAA LZ & MP"
  vpc_id      = "vpc-06febffe7b87ab37f"
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Outgoing"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = "10.200.0.0/20"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = "10.202.0.0/20"
    }
  ]
  ingress_with_source_security_group_id = [
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      description              = "HTTPS For SSM Session Manager "
      source_security_group_id = "sg-0754d9a309704addd" # laa interface endpoint security group in core-vpc-development
    }
  ]
}

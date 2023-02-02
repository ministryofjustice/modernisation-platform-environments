
locals {
  instance-userdata = <<EOF
#!/bin/bash
yum install -y httpd
cat "hello! this is a webpage" > /var/www/html/index.html
systemctl start httpd
cat "0 8 * * * root systemctl start httpd" > /etc/cron.d/httpd_cron
EOF
}


resource "aws_instance" "ec2_instance" {
  ami                    = "ami-06672d07f62285d1d"
  instance_type          = "t3a.small"
  vpc_security_group_ids = [aws_security_group.httptest_sg.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  user_data_base64       = base64encode(local.instance-userdata)
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.id
  tags = {
    Name        = "${local.environment}-landingzone-httptest"
    Environment = local.environment
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

resource "aws_security_group" "httptest_sg" {
  name        = "landingzone-httptest-sg"
  description = "Security group for TG connectivity testing between LAA LZ & MP"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "HTTP"
    cidr_blocks = ["10.200.0.0/20"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Outgoing"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ingress-from-shared-services"
  }
}
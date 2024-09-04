output "instance_ids" {
  value = tomap({
    for k, inst in aws_instance.nginx : k => inst.id
  })
}

variable "nginx_lb_sg_id" {
  type = string
}

variable "vpc_shared_id" {
  type = string
}

data "aws_ami" "latest_linux" {
  most_recent = true
  owners = ["099720109477"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "nginx" {
  for_each = toset(["eu-west-2a", "eu-west-2b"])

  ami               = data.aws_ami.latest_linux.id
  instance_type     = "t2.micro"
  availability_zone = each.value
  tags = {
    Name = "tribunals-nginx-${each.value}"
  }
  vpc_security_group_ids = [aws_security_group.allow_ssm.id]
  iam_instance_profile   = "AmazonSSMManagedInstanceCore"
  user_data              = <<-EOF
              #!/bin/bash
              ${file("${path.module}/scripts/install-nginx.sh")}
              ${file("${path.module}/scripts/add-symbolic-links.sh")}
              ${file("${path.module}/scripts/restart-nginx.sh")}
              EOF
}

resource "aws_security_group" "allow_ssm" {
  name        = "allow_ssm"
  description = "Allow SSM connection"
  vpc_id      = var.vpc_shared_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [
      var.nginx_lb_sg_id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

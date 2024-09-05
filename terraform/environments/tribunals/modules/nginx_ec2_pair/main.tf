# output "instance_ids" {
#   value = tomap({
#     for k, inst in aws_instance.nginx : k => inst.id
#   })
# }

# variable "nginx_lb_sg_id" {
#   type = string
# }

# variable "vpc_shared_id" {
#   type = string
# }

# variable "public_subnets_a_id" {
# }

# variable "public_subnets_b_id" {
# }

# variable "environment" {
# }

# data "aws_ami" "latest_linux" {
#   most_recent = true
#   owners = ["amazon"]
#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#   }
# }

# resource "aws_instance" "nginx" {
#   for_each = toset(["eu-west-2a", "eu-west-2b"])

#   ami                         = data.aws_ami.latest_linux.id
#   associate_public_ip_address = true
#   subnet_id                   = each.key == "eu-west-2a" ? var.public_subnets_a_id : var.public_subnets_b_id
#   instance_type               = "t2.micro"
#   availability_zone           = each.value
#   tags = {
#     Name = "tribunals-nginx-${each.value}"
#   }
#   vpc_security_group_ids = [aws_security_group.allow_ssm.id]
#   iam_instance_profile   = aws_iam_instance_profile.nginx_profile.name
#     user_data = <<-EOF
#               #!/bin/bash

#               echo "installing Nginx"
#               sudo yum update -y &&
#               sudo amazon-linux-extras install nginx1 -y

#               echo "Creating nginx directories"
#               sudo mkdir -p /etc/nginx/sites-enabled || echo "Failed to create sites-enabled directory"
#               sudo mkdir -p /etc/nginx/sites-available || echo "Failed to create sites-available directory"

#               echo "Copying files from S3"
#               aws s3 cp s3://${aws_s3_bucket.nginx_config.id}/sites-available /etc/nginx/sites-available --recursive

#               echo "Running add-symbolic-links.sh"
#               ${file("${path.module}/scripts/add-symbolic-links.sh")}
#               echo "Running restart-nginx.sh"
#               ${file("${path.module}/scripts/restart-nginx.sh")}

#               echo "Nginx setup completed"
#               EOF
# }

# resource "aws_security_group" "allow_ssm" {
#   name        = "allow_ssm"
#   description = "Allow SSM connection"
#   vpc_id      = var.vpc_shared_id

#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     security_groups = [
#       var.nginx_lb_sg_id
#     ]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_s3_bucket" "nginx_config" {
#   bucket = "tribunals-nginx-config-files-${var.environment}"
# }

# resource "aws_s3_object" "sites_available" {
#   for_each = fileset("${path.module}/sites-available", "*")

#   bucket = aws_s3_bucket.nginx_config.id
#   key    = "sites-available/${each.value}"
#   source = "${path.module}/sites-available/${each.value}"
# }

# resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
#   role       = aws_iam_role.nginx_role.name
# }

# resource "aws_iam_role" "nginx_role" {
#   name = "nginx-ssm-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   role       = aws_iam_role.nginx_role.name
# }

# resource "aws_iam_instance_profile" "nginx_profile" {
#   name = "nginx-ssm-profile"
#   role = aws_iam_role.nginx_role.name
# }
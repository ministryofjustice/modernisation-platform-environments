terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

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

variable "public_subnets_a_id" {
  type = string
}

variable "public_subnets_b_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "s3_encryption_key_arn" {
  type = string
}

data "aws_ami" "latest_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "nginx" {
  #checkov:skip=CKV_AWS_88:"EC2 instances require public IPs as they are internet-facing nginx servers"
  for_each = toset(["eu-west-2a", "eu-west-2b"])

  ami                         = data.aws_ami.latest_linux.id
  associate_public_ip_address = true
  subnet_id                   = each.key == "eu-west-2a" ? var.public_subnets_a_id : var.public_subnets_b_id
  instance_type               = "t2.micro"
  availability_zone           = each.value
  ebs_optimized               = true
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    encrypted = true
  }
  tags = {
    Name = "tribunals-nginx-${each.value}"
  }
  vpc_security_group_ids = [aws_security_group.allow_ssm.id]
  iam_instance_profile   = aws_iam_instance_profile.nginx_profile.name
  user_data              = <<-EOF
              #!/bin/bash

              echo "installing Nginx"
              sudo yum update -y &&
              sudo amazon-linux-extras install nginx1 -y

              echo "Creating nginx directories"
              sudo mkdir -p /etc/nginx/sites-enabled || echo "Failed to create sites-enabled directory"
              sudo mkdir -p /etc/nginx/sites-available || echo "Failed to create sites-available directory"

              echo "Copying files from S3"
              aws s3 cp s3://${aws_s3_bucket.nginx_config.id}/nginx.conf /etc/nginx/nginx.conf
              aws s3 cp s3://${aws_s3_bucket.nginx_config.id}/sites-available /etc/nginx/sites-available --recursive

              echo "Running add-symbolic-links.sh"
              ${file("${path.module}/scripts/add-symbolic-links.sh")}
              echo "Running restart-nginx.sh"
              ${file("${path.module}/scripts/restart-nginx.sh")}

              echo "Nginx setup completed"
              EOF
}

resource "aws_security_group" "allow_ssm" {
  #checkov:skip=CKV_AWS_382:"EC2 instances require unrestricted egress"
  name        = "allow_ssm"
  description = "Allow SSM connection"
  vpc_id      = var.vpc_shared_id

  ingress {
    description = "Allow traffic from load balancer"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [
      var.nginx_lb_sg_id
    ]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "nginx_config" {
  #checkov:skip=CKV2_AWS_62:"Event notifications not required for this bucket"
  #checkov:skip=CKV_AWS_144:"Cross-region replication not required"
  #checkov:skip=CKV_AWS_18:"Access logging not required"
  #checkov:skip=CKV2_AWS_61:"Lifecycle configuration not required for nginx config files that need to be retained"
  bucket = "tribunals-nginx-config-files-${var.environment}"
}

resource "aws_s3_bucket_versioning" "nginx_bucket_versioning" {
  bucket = aws_s3_bucket.nginx_config.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "nginx_config_encryption" {
  bucket = aws_s3_bucket.nginx_config.id

  rule {

    apply_server_side_encryption_by_default {
      kms_master_key_id = var.s3_encryption_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "nginx_config_access_block" {
  bucket = aws_s3_bucket.nginx_config.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "sites_available" {
  for_each = fileset("${path.module}/sites-available", "*")

  bucket = aws_s3_bucket.nginx_config.id
  key    = "sites-available/${each.value}"
  source = "${path.module}/sites-available/${each.value}"
  # Use md5 to detect changes in the sites-available folder
  etag = filemd5("${path.module}/sites-available/${each.value}")
}

resource "aws_s3_object" "nginx_conf" {
  bucket = aws_s3_bucket.nginx_config.id
  key    = "nginx.conf"
  source = "${path.module}/nginx-conf/nginx.conf"
  # Use md5 to detect changes in the nginx.conf file
  etag = filemd5("${path.module}/nginx-conf/nginx.conf")
}

resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.nginx_role.name
}

resource "aws_iam_role" "nginx_role" {
  name = "nginx-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.nginx_role.name
}

resource "aws_iam_instance_profile" "nginx_profile" {
  name = "nginx-ssm-profile"
  role = aws_iam_role.nginx_role.name
}
# Test infrastructure for network connectivity checks

# Internal HTTPS server, a target for the Grafana Cloud PDC agent (see observability_platform.tf)
data "aws_ami" "amazon_linux_2023" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "internal" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  vpc_security_group_ids      = [aws_security_group.internal_server.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ssm_instance_profile.name
  ebs_optimized               = true
  monitoring                  = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted = true
  }

  user_data_replace_on_change = true
  user_data                   = <<-EOF
              #!/bin/bash
              set -euxo pipefail
              dnf install -y httpd mod_ssl openssl

              # IMDSv2 token
              TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" \
              -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

              # Private IP of this instance
              PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
              http://169.254.169.254/latest/meta-data/local-ipv4)

              # Self-signed certificate for the private IP
              openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
              -keyout /etc/pki/tls/private/selfsigned.key \
              -out /etc/pki/tls/certs/selfsigned.crt \
              -subj "/CN=$PRIVATE_IP" -addext "subjectAltName=IP:$PRIVATE_IP"
              sed -i \
              -e 's|^SSLCertificateFile .*|SSLCertificateFile /etc/pki/tls/certs/selfsigned.crt|' \
              -e 's|^SSLCertificateKeyFile .*|SSLCertificateKeyFile /etc/pki/tls/private/selfsigned.key|' \
              /etc/httpd/conf.d/ssl.conf

              echo "<h1>WELCOME TO THE MODERNISATION PLATFORM</h1>" > /var/www/html/index.html
              # Static JSON for a Grafana Infinity or JSON API data source to query through PDC
              echo '{"message": "Hello from cooker through Grafana Cloud PDC", "value": 42}' > /var/www/html/pdc-test.json

              systemctl enable --now httpd
              EOF

  # Avoid replacing the instance every time Amazon publishes a new AMI
  lifecycle {
    ignore_changes = [ami]
  }

  tags = merge(local.tags, {
    Name = "test-internal-server"
  })
}

# IAM role for SSM access
resource "aws_iam_role" "ssm_role" {
  name = "test-networking-ssm-role"

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

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "test-networking-ssm-instance-profile"
  role = aws_iam_role.ssm_role.name

  tags = local.tags
}

resource "aws_security_group" "internal_server" {
  name        = "internal-server-${var.networking[0].application}"
  description = "Allow inbound traffic to internal server"
  vpc_id      = data.aws_vpc.shared.id

  tags = local.tags
}

# Package repositories and SSM
resource "aws_security_group_rule" "internal_egress_1" {
  description       = "Allow outbound HTTPS"
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.internal_server.id
}

resource "aws_security_group_rule" "internal_egress_2" {
  description       = "Allow outbound HTTP"
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.internal_server.id
}

resource "aws_security_group_rule" "internal_ingress_pdc_agent" {
  count = local.is-development ? 1 : 0

  description              = "Allow HTTPS from the Grafana Cloud PDC agent"
  type                     = "ingress"
  source_security_group_id = module.observability_platform_tenant[0].grafana_cloud_pdc_agent_security_group_id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.internal_server.id
}

# Public web server, not currently deployed

# data "aws_ami" "amazon_linux_2" {
#   most_recent = true

#   owners = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#   }

#   filter {
#     name   = "state"
#     values = ["available"]
#   }
# }

# resource "aws_instance" "web" {
#   ami                         = data.aws_ami.amazon_linux_2.id
#   instance_type               = "t2.micro"
#   subnet_id                   = data.aws_subnet.public_subnets_a.id
#   vpc_security_group_ids      = [aws_security_group.web_server.id]
#   associate_public_ip_address = true
#   iam_instance_profile        = aws_iam_instance_profile.ssm_instance_profile.name

#   user_data = <<-EOF
#               #!/bin/bash
#               yum update -y
#               yum install -y httpd mod_ssl
#               systemctl enable httpd
#               systemctl start httpd
#               echo "<h1>WELCOME TO THE MODERNISATION PLATFORM</h1>" > /var/www/html/index.html

#               # IMDSv2 token
#               TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
#               -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

#               PUBLIC_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
#               -s http://169.254.169.254/latest/meta-data/public-ipv4)

#               # Generate self-signed cert
#               openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
#               -keyout /etc/pki/tls/private/selfsigned.key \
#               -out /etc/pki/tls/certs/selfsigned.crt \
#               -subj "/CN=$PUBLIC_IP"

#               systemctl restart httpd
#               EOF

#   tags = {
#     Name = "test-web-server"
#   }
# }

# resource "aws_security_group" "web_server" {

#   name        = "web-server-${var.networking[0].application}"
#   description = "Allow traffic to web server"
#   vpc_id      = data.aws_vpc.shared.id
# }

# resource "aws_security_group_rule" "web_server_1" {

#   security_group_id = aws_security_group.web_server.id
#   type              = "ingress"
#   from_port         = 443
#   to_port           = 443
#   protocol          = "tcp"
#   cidr_blocks = [
#     "176.116.118.96/32", # My public IP
#     "10.231.8.0/21",     # house-sandbox vpc
#     "172.20.0.0/16"      # cloud-platform vpc
#   ]
# }

# resource "aws_security_group_rule" "web_server_2" {

#   security_group_id = aws_security_group.web_server.id
#   type              = "ingress"
#   from_port         = 80
#   to_port           = 80
#   protocol          = "tcp"
#   cidr_blocks = [
#     "176.116.118.96/32", # My public IP
#     "10.231.8.0/21",     # house-sandbox vpc
#     "172.20.0.0/16"      # cloud-platform vpc
#   ]
# }

# resource "aws_security_group_rule" "web_server_3" {

#   security_group_id = aws_security_group.web_server.id
#   type              = "egress"
#   from_port         = 443
#   to_port           = 443
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
# }

# resource "aws_security_group_rule" "web_server_4" {

#   security_group_id = aws_security_group.web_server.id
#   type              = "egress"
#   from_port         = 80
#   to_port           = 80
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
# }

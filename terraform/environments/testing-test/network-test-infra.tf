# # Test infrastructure for network connectivity checks
# # This file has been created to be run specifically in the testing-test account, to create test instances and security groups for testing network connectivity from the house-sandbox and garden-sandbox accounts. It should not be run in any other account as it contains hardcoded values for VPC and subnet IDs that are specific to the testing-test account.

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
#   subnet_id                   = "Redacted" #To run this code locally you will need the ID of a Public subnet
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

# resource "aws_instance" "internal" {
#   ami                         = data.aws_ami.amazon_linux_2.id
#   instance_type               = "t2.micro"
#   subnet_id                   = "Redacted" #To run this code locally you will need the ID of the private subnet
#   vpc_security_group_ids      = [aws_security_group.internal_server.id]
#   associate_public_ip_address = false
#   iam_instance_profile        = aws_iam_instance_profile.ssm_instance_profile.name

#   user_data = <<-EOF
#               #!/bin/bash
#               yum update -y
#               yum install -y httpd mod_ssl
#               systemctl enable httpd
#               systemctl start httpd
#               # Simple welcome page
#               echo "<h1>WELCOME TO THE MODERNISATION PLATFORM</h1>" > /var/www/html/index.html

#               # IMDSv2 token
#               TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
#               -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

#               # Private IP of this instance
#               PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
#               -s http://169.254.169.254/latest/meta-data/local-ipv4)

#               # Generate self-signed cert for private IP
#               openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
#               -keyout /etc/pki/tls/private/selfsigned.key \
#               -out /etc/pki/tls/certs/selfsigned.crt \
#               -subj "/CN=$PRIVATE_IP"

#               systemctl restart httpd
#               EOF

#   tags = {
#     Name = "test-internal-server"
#   }
# }

# #IAM role for SSM access
# resource "aws_iam_role" "ssm_role" {
#   name = "test-networking-ssm-role"

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

# resource "aws_iam_role_policy_attachment" "ssm_attach" {
#   role       = aws_iam_role.ssm_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# resource "aws_iam_instance_profile" "ssm_instance_profile" {
#   name = "test-networking-ssm-instance-profile"
#   role = aws_iam_role.ssm_role.name
# }

# # Security group for test instances

# resource "aws_security_group" "web_server" {

#   name        = "web-server-testing-test"
#   description = "Allow traffic to web server"
#   vpc_id      = "Redacted" #To run this code locally you will need the vpc ID
# }

# resource "aws_security_group_rule" "web_server_1" {

#   security_group_id = aws_security_group.web_server.id
#   type              = "ingress"
#   from_port         = 443
#   to_port           = 443
#   protocol          = "tcp"
#   cidr_blocks = [
#     "redacted/32",   # add your public ip address here
#     "10.231.8.0/21", # house-sandbox vpc
#     "172.20.0.0/16"  # cloud-platform vpc
#   ]
# }

# resource "aws_security_group_rule" "web_server_2" {

#   security_group_id = aws_security_group.web_server.id
#   type              = "ingress"
#   from_port         = 80
#   to_port           = 80
#   protocol          = "tcp"
#   cidr_blocks = [
#     "redacted/32",   # add your public ip address here
#     "10.231.8.0/21", # house-sandbox vpc
#     "172.20.0.0/16"  # cloud-platform vpc
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


# resource "aws_security_group" "internal_server" {

#   name        = "internal-server-testing-test"
#   description = "Allow inbound traffic to internal server"
#   vpc_id      = "Redacted" #To run this code locally you will need the vpc ID
# }

# resource "aws_security_group_rule" "internal_egress_1" {

#   type              = "egress"
#   cidr_blocks       = ["0.0.0.0/0"]
#   from_port         = 443
#   to_port           = 443
#   protocol          = "tcp"
#   security_group_id = aws_security_group.internal_server.id
# }

# resource "aws_security_group_rule" "internal_egress_2" {

#   type              = "egress"
#   cidr_blocks       = ["0.0.0.0/0"]
#   from_port         = 80
#   to_port           = 80
#   protocol          = "tcp"
#   security_group_id = aws_security_group.internal_server.id
# }

# resource "aws_security_group_rule" "internal_egress_3" {

#   type              = "egress"
#   cidr_blocks       = ["0.0.0.0/0"]
#   from_port         = 5432
#   to_port           = 5432
#   protocol          = "tcp"
#   security_group_id = aws_security_group.internal_server.id
# }

# resource "aws_security_group_rule" "internal_ingress_1" {

#   type = "ingress"
#   cidr_blocks = [
#     "10.231.8.0/21", # house-sandbox vpc
#     "10.231.0.0/21", # garden-sandbox vpc
#     "172.20.0.0/16"  # cloud-platform vpc
#   ]
#   from_port         = 443
#   to_port           = 443
#   protocol          = "tcp"
#   security_group_id = aws_security_group.internal_server.id
# }

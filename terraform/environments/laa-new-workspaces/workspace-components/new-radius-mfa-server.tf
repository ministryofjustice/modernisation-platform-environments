##############################################
### RADIUS Server Infrastructure for MFA
###
### Deploys EC2 instances running RADIUS server
### software for multi-factor authentication.
###
##############################################

##############################################
### Security Group for RADIUS Servers
##############################################

resource "aws_security_group" "radius_server" {

  name_prefix = "${local.application_name}-${local.environment}-radius-"
  description = "Security group for RADIUS MFA servers"
  vpc_id      = aws_vpc.workspaces.id

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-radius-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "radius_server_udp_auth" {

  type              = "ingress"
  from_port         = 1812
  to_port           = 1812
  protocol          = "udp"
  cidr_blocks       = [aws_vpc.workspaces.cidr_block]
  security_group_id = aws_security_group.radius_server.id
  description       = "RADIUS authentication from Microsoft AD"
}

resource "aws_security_group_rule" "radius_server_udp_accounting" {

  type              = "ingress"
  from_port         = 1813
  to_port           = 1813
  protocol          = "udp"
  cidr_blocks       = [aws_vpc.workspaces.cidr_block]
  security_group_id = aws_security_group.radius_server.id
  description       = "RADIUS accounting"
}

resource "aws_security_group_rule" "radius_server_ssh" {

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.workspaces.cidr_block]
  security_group_id = aws_security_group.radius_server.id
  description       = "SSH for management"
}

resource "aws_security_group_rule" "radius_server_egress_all" {

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.radius_server.id
  description       = "Allow all outbound traffic"
}

# # Separate ingress rule to avoid circular dependency
# resource "aws_security_group_rule" "radius_server_from_alb" {

#   type                     = "ingress"
#   from_port                = 443
#   to_port                  = 443
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.radius_server.id
#   source_security_group_id = aws_security_group.radius_alb.id
#   description              = "HTTPS from ALB for LinOTP portal"
# }

##############################################
### IAM Role for RADIUS Servers
##############################################

data "aws_iam_policy_document" "radius_server_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "radius_server" {

  name_prefix        = "${local.application_name}-${local.environment}-radius-"
  assume_role_policy = data.aws_iam_policy_document.radius_server_assume_role.json

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-radius-role"
    }
  )
}

# Allow RADIUS servers to read secrets (for configuration)
resource "aws_iam_role_policy" "radius_server_secrets" {

  name_prefix = "radius-secrets-access-"
  role        = aws_iam_role.radius_server.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.radius_shared_secret.arn,
          aws_secretsmanager_secret.linotp_admin_password.arn,
          aws_secretsmanager_secret.mariadb_root_password.arn,
        ]
      }
    ]
  })
}

# Attach SSM managed policy for Systems Manager access
resource "aws_iam_role_policy_attachment" "radius_server_ssm" {

  role       = aws_iam_role.radius_server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "radius_server" {

  name_prefix = "${local.application_name}-${local.environment}-radius-"
  role        = aws_iam_role.radius_server.name

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-radius-profile"
    }
  )
}

##############################################
### Get Latest Amazon Linux 2 AMI
##############################################

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

##############################################
### RADIUS Server EC2 Instance (LinOTP + FreeRADIUS)
###
### LinOTP provides self-service MFA enrollment portal
### FreeRADIUS provides RADIUS authentication
##############################################

resource "aws_instance" "radius_server" {

  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.medium" # Required for LinOTP + MariaDB + Apache
  subnet_id     = aws_subnet.private_a.id

  vpc_security_group_ids = [aws_security_group.radius_server.id]
  iam_instance_profile   = aws_iam_instance_profile.radius_server.name

  # LinOTP + FreeRADIUS installation script
  user_data = base64gzip(templatefile("${path.module}/userdata/install-linotp-freeradius.sh", {
    region                    = "eu-west-2"
    radius_secret_arn         = aws_secretsmanager_secret.radius_shared_secret.arn
    linotp_admin_password_arn = aws_secretsmanager_secret.linotp_admin_password.arn
    mariadb_root_password_arn = aws_secretsmanager_secret.mariadb_root_password.arn
    environment               = local.environment
    vpc_cidr                  = aws_vpc.workspaces.cidr_block
  }))

  user_data_replace_on_change = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30 # Increased for LinOTP + MariaDB
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 1
  }

  tags = merge(
    local.tags,
    {
      "Name"       = "${local.application_name}-${local.environment}-radius"
      "RADIUSNode" = "true"
      "Backup"     = "true"
      "MFAType"    = "LinOTP"
    }
  )

  lifecycle {
    ignore_changes = [
      ami, # Don't replace on AMI updates
    ]
  }
}

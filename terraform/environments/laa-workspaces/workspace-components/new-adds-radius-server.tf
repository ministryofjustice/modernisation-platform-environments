##############################################
### RADIUS Server Infrastructure for MFA
###
### Deploys EC2 instances running RADIUS server
### software for multi-factor authentication.
###
### Choose one deployment option:
### 1. Duo Authentication Proxy (recommended)
### 2. Azure MFA NPS Extension (Windows Server)
### 3. FreeRADIUS with Google Authenticator
##############################################

##############################################
### RADIUS Shared Secret
##############################################

resource "random_password" "radius_shared_secret" {
  count = local.environment == "development" ? 1 : 0

  length  = 32
  special = true
}

resource "aws_secretsmanager_secret" "radius_shared_secret" {
  count = local.environment == "development" ? 1 : 0

  name_prefix             = "${local.application_name}-${local.environment}-radius-secret-"
  description             = "RADIUS shared secret for WorkSpaces MFA"
  recovery_window_in_days = 0 # For development - allows immediate deletion

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-radius-secret"
      "Type" = "RADIUS"
    }
  )
}

resource "aws_secretsmanager_secret_version" "radius_shared_secret" {
  count = local.environment == "development" ? 1 : 0

  secret_id     = aws_secretsmanager_secret.radius_shared_secret[0].id
  secret_string = random_password.radius_shared_secret[0].result
}

##############################################
### Security Group for RADIUS Servers
##############################################

resource "aws_security_group" "radius_server" {
  count = local.environment == "development" ? 1 : 0

  name_prefix = "${local.application_name}-${local.environment}-radius-"
  description = "Security group for RADIUS MFA servers"
  vpc_id      = aws_vpc.workspaces[0].id

  # RADIUS authentication from Microsoft AD subnets
  ingress {
    from_port   = 1812
    to_port     = 1812
    protocol    = "udp"
    cidr_blocks = [aws_vpc.workspaces[0].cidr_block]
    description = "RADIUS authentication from Microsoft AD"
  }

  # RADIUS accounting (optional)
  ingress {
    from_port   = 1813
    to_port     = 1813
    protocol    = "udp"
    cidr_blocks = [aws_vpc.workspaces[0].cidr_block]
    description = "RADIUS accounting"
  }

  # SSH for management (restrict to bastion/management IPs in production)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.workspaces[0].cidr_block]
    description = "SSH for management"
  }

  # Allow all outbound (for RADIUS proxy to reach MFA provider APIs)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

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
  count = local.environment == "development" ? 1 : 0

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
  count = local.environment == "development" ? 1 : 0

  name_prefix = "radius-secrets-access-"
  role        = aws_iam_role.radius_server[0].id

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
          aws_secretsmanager_secret.radius_shared_secret[0].arn,
          # Add other secrets as needed (Duo keys, etc.)
        ]
      }
    ]
  })
}

# Attach SSM managed policy for Systems Manager access
resource "aws_iam_role_policy_attachment" "radius_server_ssm" {
  count = local.environment == "development" ? 1 : 0

  role       = aws_iam_role.radius_server[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch agent policy
resource "aws_iam_role_policy_attachment" "radius_server_cloudwatch" {
  count = local.environment == "development" ? 1 : 0

  role       = aws_iam_role.radius_server[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "radius_server" {
  count = local.environment == "development" ? 1 : 0

  name_prefix = "${local.application_name}-${local.environment}-radius-"
  role        = aws_iam_role.radius_server[0].name

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-radius-profile"
    }
  )
}

##############################################
### Get Latest Amazon Linux 2023 AMI
##############################################

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
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
### RADIUS Server EC2 Instances (FreeRADIUS)
###
### Deploys 2 instances for high availability
### using FreeRADIUS with Google Authenticator
##############################################

resource "aws_instance" "radius_server" {
  count = local.environment == "development" ? 2 : 0  # 2 for HA

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.small"  # Sufficient for <100 users
  subnet_id     = [aws_subnet.private_a[0].id, aws_subnet.private_b[0].id][count.index % 2]

  vpc_security_group_ids = [aws_security_group.radius_server[0].id]
  iam_instance_profile   = aws_iam_instance_profile.radius_server[0].name

  # FreeRADIUS installation script with Google Authenticator
  user_data = templatefile("${path.module}/scripts/install-freeradius.sh", {
    region            = "eu-west-2"
    radius_secret_arn = aws_secretsmanager_secret.radius_shared_secret[0].arn
    environment       = local.environment
  })

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2 only
    http_put_response_hop_limit = 1
  }

  tags = merge(
    local.tags,
    {
      "Name"       = "${local.application_name}-${local.environment}-radius-${count.index + 1}"
      "RADIUSNode" = "true"
      "Backup"     = "true"
      "MFAType"    = "FreeRADIUS"
    }
  )

  lifecycle {
    ignore_changes = [
      ami,  # Don't replace on AMI updates
    ]
  }
}

##############################################
### CloudWatch Log Group for RADIUS Logs
##############################################

resource "aws_cloudwatch_log_group" "radius_logs" {
  count = local.environment == "development" ? 1 : 0

  name              = "/aws/ec2/${local.application_name}-${local.environment}/radius"
  retention_in_days = 30

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-radius-logs"
    }
  )
}

##############################################
### CloudWatch Alarms for RADIUS Servers
##############################################

resource "aws_cloudwatch_metric_alarm" "radius_server_health" {
  count = local.environment == "development" ? 2 : 0

  alarm_name          = "${local.application_name}-${local.environment}-radius-${count.index + 1}-unhealthy"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "RADIUS server ${count.index + 1} has failed status checks"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.radius_server[count.index].id
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-radius-${count.index + 1}-alarm"
    }
  )
}

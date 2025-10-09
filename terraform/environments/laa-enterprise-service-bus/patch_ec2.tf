# Security Group allowing SSM (no inbound needed)
resource "aws_security_group" "ec2_debug_sg" {
  count       = local.environment == "test" ? 1 : 0
  name        = "${local.application_name_short}-${local.environment}-ec2-debug-security-group"
  description = "EC2 Debug Security Group"
  vpc_id      = data.aws_vpc.shared.id

  revoke_rules_on_delete = true

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-patch-cwa-extract-lambda-security-group" }
  )
}

resource "aws_security_group_rule" "ec2_debug_egress_ecp" {
  count             = local.environment == "test" ? 1 : 0
  type              = "egress"
  from_port         = 2484
  to_port           = 2484
  protocol          = "tcp"
  cidr_blocks       = ["10.205.11.0/26", "10.205.11.64/26"] # Patch CCMS Database IP
  security_group_id = aws_security_group.ec2_debug_sg[0].id
  description       = "Outbound 2484 Access to CWA DB Safe3 in ECP"
}

resource "aws_security_group_rule" "ec2_debug_egress_https_endpoint" {
  count                    = local.environment == "test" ? 1 : 0
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.ec2_debug_sg[0].id
  description              = "Outbound 443 to internet"
}

# IAM Role for SSM
resource "aws_iam_role" "ec2_debug_role" {
  count = local.environment == "test" ? 1 : 0
  name  = "ec2-debug-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_debug_policy" {
  name = "ec2-debug-policy"
  role = aws_iam_role.ec2_debug_role[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = "*"
      },
    ]
  })
}

# Attach SSM managed policy
resource "aws_iam_role_policy_attachment" "ec2_debug_policy_attach" {
  count      = local.environment == "test" ? 1 : 0
  role       = aws_iam_role.ec2_debug_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_debug_instance_profile" {
  count = local.environment == "test" ? 1 : 0
  name  = "ec2-debug-profile"
  role  = aws_iam_role.ec2_debug_role[0].name
}

# EC2 Instance
resource "aws_instance" "ssm_instance" {
  count                       = local.environment == "test" ? 1 : 0
  ami                         = "ami-0336cdd409ab5eec4"
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  vpc_security_group_ids      = [aws_security_group.ec2_debug_sg[0].id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_debug_instance_profile[0].name
  associate_public_ip_address = false

  tags = {
    Name = "EC2-Debug-Instance"
  }
}
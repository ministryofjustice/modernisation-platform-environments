# IAM Role for SSOGEN EC2
resource "aws_iam_role" "ssogen_ec2" {
  name = "ssogen-ec2-role-${local.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
  tags = merge(local.tags, {
    Name = "ssogen-ec2-role-${local.environment}"
  })
}

# Instance Profile to attach to EC2
resource "aws_iam_instance_profile" "ssogen_instance_profile" {
  name = "ssogen-instance-profile-${local.environment}"
  role = aws_iam_role.ssogen_ec2.name
  tags = merge(local.tags, {
    Name = "ssogen-instance-profile-${local.environment}"
  })
}

# Attach SSM permissions (Session Manager, logging, patching, etc.)
resource "aws_iam_role_policy_attachment" "ssogen_ssm" {
  role       = aws_iam_role.ssogen_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Optional: Secrets Manager read-only (use only if needed)
resource "aws_iam_role_policy_attachment" "ssogen_secrets_read" {
  role       = aws_iam_role.ssogen_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "ssogen_ssm" {
  role       = aws_iam_role.ssogen_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = data.aws_vpc.shared.id
  service_name      = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = local.private_subnets
  security_group_ids = [aws_security_group.ssogen_sg.id]
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = data.aws_vpc.shared.id
  service_name      = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = local.private_subnets
  security_group_ids = [aws_security_group.ssogen_sg.id]
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = data.aws_vpc.shared.id
  service_name      = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = local.private_subnets
  security_group_ids = [aws_security_group.ssogen_sg.id]
}

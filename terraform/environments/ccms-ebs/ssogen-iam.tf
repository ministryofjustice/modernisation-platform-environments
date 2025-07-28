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

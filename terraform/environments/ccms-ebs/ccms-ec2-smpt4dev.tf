#Create AWS IAM Role Profile for EC2
resource "aws_iam_role" "smtp4dev_ec2_ssm_role" {
  count    = local.is-production ? 0 : 1
  name = "smtp4dev-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AmazonSSMManagedInstanceCore policy to the role
resource "aws_iam_role_policy_attachment" "smtp4dev_ssm_core_attach" {
  count    = local.is-production ? 0 : 1
  role       = aws_iam_role.smtp4dev_ec2_ssm_role[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile for SMTP4dev EC2 to use the role
resource "aws_iam_instance_profile" "smtp4dev_ec2_ssm_profile" {
  count    = local.is-production ? 0 : 1
  name = "smtp4dev-instance-profile"
  role = aws_iam_role.smtp4dev_ec2_ssm_role[count.index].name
}

# Build smtp4dev EC2 
resource "aws_instance" "smtp4dev_mock_server" {
  count    = local.is-production ? 0 : 1
  instance_type          = "t3.medium"
  ami                    = "ami-07eb36e50da2fcccd"
  vpc_security_group_ids = [aws_security_group.smtp4dev_mock_server_sg[count.index].id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.smtp4dev_ec2_ssm_profile[count.index].name

  user_data_replace_on_change = true
  user_data = base64encode(templatefile("./templates/ec2_user_data_smpt4dev.sh", {
    environment               = "${local.environment}"
  }))

  lifecycle {
    ignore_changes = [     
      user_data,
      user_data_replace_on_change
    ]
  }

  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-smtp4dev", local.application_name, local.environment)) },
    { instance-scheduling = "skip-auto-start" },
    { backup = "true" }
  )
}
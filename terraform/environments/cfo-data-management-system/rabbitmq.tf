# Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon-linux-2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# RabbitMQ EC2 Instance
resource "aws_instance" "rabbitmq" {
  ami                    = data.aws_ami.amazon-linux-2023.id
  instance_type          = "t3.small"
  subnet_id              = data.aws_subnet.private_subnets_a.id
  vpc_security_group_ids = [aws_security_group.rabbitmq.id]
  iam_instance_profile   = aws_iam_instance_profile.rabbitmq.name

  # Prevent accidental termination via Terraform or the console
  disable_api_termination = local.is-production

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    # Retain the volume if the instance is ever terminated
    delete_on_termination = false
  }

  user_data_base64 = base64encode(templatefile("${path.module}/templates/rabbitmq-userdata.sh.tftpl", {
    secret_arn = aws_secretsmanager_secret.rabbitmq-password.arn
    region     = data.aws_region.current.name
  }))

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-rabbitmq" }
  )

  lifecycle {
    # Prevent replacement when a newer AMI is published or user_data drifts after first boot
    ignore_changes = [ami, user_data_base64]
  }
}
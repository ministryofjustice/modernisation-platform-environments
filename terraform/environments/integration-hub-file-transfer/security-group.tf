resource "aws_security_group" "transfer" {
  name        = "${local.application_name}-${local.environment}-transfer"
  description = "Allow SFTP and FTPS access to the Transfer Family server"
  vpc_id      = data.aws_vpc.shared.id

  dynamic "ingress" {
    for_each = local.transfer_user_cidr_blocks

    content {
      description = "SFTP from ${ingress.key}"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ingress.value
    }
  }

  dynamic "ingress" {
    for_each = local.transfer_user_cidr_blocks

    content {
      description = "FTPS control from ${ingress.key}"
      from_port   = 21
      to_port     = 21
      protocol    = "tcp"
      cidr_blocks = ingress.value
    }
  }

  dynamic "ingress" {
    for_each = local.transfer_user_cidr_blocks

    content {
      description = "FTPS data from ${ingress.key}"
      from_port   = 8192
      to_port     = 8200
      protocol    = "tcp"
      cidr_blocks = ingress.value
    }
  }

  egress {
    description = "Allow all outbound IPv4 traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}
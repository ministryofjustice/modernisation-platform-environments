resource "aws_security_group" "oem_app_efs_sg" {
  name_prefix = "${local.application_name}-app-efs-sg-"
  description = "Allow inbound access from instances"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(tomap(
    { "Name" = "${local.application_name}-app-efs-sg" }
  ), local.tags)

  ingress {
    protocol    = "tcp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  lifecycle {
    create_before_destroy = true
  }
}
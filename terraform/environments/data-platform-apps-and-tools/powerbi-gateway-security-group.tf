
resource "aws_security_group" "powerbi_gateway" {
  name        = local.environment_configuration.powerbi_gateway_ec2.instance_name
  description = local.environment_configuration.powerbi_gateway_ec2.instance_name
  vpc_id      = data.aws_vpc.shared.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.environment_configuration.vpc_cidr]
  }

  tags = local.tags
}

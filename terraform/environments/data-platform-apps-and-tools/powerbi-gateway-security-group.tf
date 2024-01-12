
resource "aws_security_group" "powerbi_gateway" {
  name        = local.environment_configuration.powerbi_gateway_ec2.instance_name
  description = local.environment_configuration.powerbi_gateway_ec2.instance_name
  vpc_id      = data.aws_vpc.shared.id

  # https://learn.microsoft.com/en-us/data-integration/gateway/service-gateway-communication#ports
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5671
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 9352
    to_port     = 9354
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

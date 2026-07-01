# EC2 Instance Connect Endpoint (EICE)
resource "aws_ec2_instance_connect_endpoint" "main" {
  subnet_id          = data.aws_subnet.private_subnets_a.id
  security_group_ids = [aws_security_group.eice.id]
  preserve_client_ip = false

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-eice" }
  )
}

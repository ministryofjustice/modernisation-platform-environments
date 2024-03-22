resource "aws_eip" "transfer_server" {
  count = length(data.aws_availability_zones.available.names)

  domain = "vpc"

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-transfer-server"
    }
  )
}

resource "aws_eip" "transfer_server" {
  count = length(module.vpc.public_subnets)
  domain = "vpc"

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-transfer-server"
    }
  )
}

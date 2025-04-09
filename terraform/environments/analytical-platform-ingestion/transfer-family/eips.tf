resource "aws_eip" "transfer_server" {
  count = length(data.aws_subnets.isolated_public.ids)

  domain = "vpc"

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-transfer-server"
    }
  )
}

# Pre-req - security group
resource "aws_security_group" "onprem_gateway" {
  name        = "onprem-gateway"
  description = "Controls access onprem gateway instance"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(local.on_prem_dgw_name) }
  )
}

resource "aws_eip" "this" {
  count  = length(local.transfer_subnet_ids)
  domain = "vpc"
  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-transfer-server-${count.index + 1}"
    }
  )
}
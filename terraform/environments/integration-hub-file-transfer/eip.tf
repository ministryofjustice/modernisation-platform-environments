resource "aws_eip" "this" {
  count  = length(local.transfer_subnet_ids)
  domain = "vpc"
}
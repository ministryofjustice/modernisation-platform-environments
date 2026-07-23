resource "aws_eip" "this" {
  count  = local.is-production ==  true ? length(data.aws_subnets.shared-public.ids) : 1
  domain = "vpc"
}
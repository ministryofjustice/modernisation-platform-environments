resource "aws_route53_zone" "private" {
  name = "azure.hmpp.root"

  vpc {
    vpc_id = local.vpc_id
  }
}
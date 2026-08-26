#create a route53 hosted zone in terraform
resource "aws_route53_zone" "maindns" {
  name = var.domain_name

  dynamic "vpc" {
    for_each = var.private_hosted_zone ? [var.vpc] : []
    content {
      vpc_id = vpc.value
    }
  }

  tags = merge(var.tags, local.tags)
}

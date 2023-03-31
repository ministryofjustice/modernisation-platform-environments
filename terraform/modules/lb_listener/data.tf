data "aws_lb" "this" {
  count = var.load_balancer_arn != null ? 1 : 0
  arn   = var.load_balancer_arn
}

data "aws_vpc" "this" {
  tags = {
    Name = "${var.business_unit}-${var.environment}"
  }
}

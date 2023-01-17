data "aws_lb" "this" {
  arn = var.load_balancer_arn
}

data "aws_vpc" "this" {
  tags = {
    Name = "${var.business_unit}-${var.environment}"
  }
}

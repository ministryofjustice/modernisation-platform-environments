resource "aws_lb" "nginx_lb" {
  name               = "tribunals-nginx"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.nginx_lb_sg_id]
  subnets            = var.subnets_shared_public_ids
}

resource "aws_lb_target_group" "nginx_lb_tg" {
  name     = "tribunals-nginx"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_shared_id
  health_check {
    matcher = "302"
  }
}

variable "nginx_instance_ids" {
  type = map(string)
}

variable "nginx_lb_sg_id" {
  type = string
}

variable "subnets_shared_public_ids" {
}

variable "vpc_shared_id" {
  type = string
}

resource "aws_lb_target_group_attachment" "nginx_lb_tg_attachment" {
  for_each         = var.nginx_instance_ids

  target_group_arn = aws_lb_target_group.nginx_lb_tg.arn
  target_id        = each.value
  port             = 80
}

resource "aws_lb_listener" "nginx_lb_listener" {
  load_balancer_arn = aws_lb.nginx_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_lb_tg.arn
  }
}

resource "aws_lb_listener" "nginx_lb_listener_https" {
  load_balancer_arn = aws_lb.nginx_lb.arn
  port              = "443"
  protocol          = "HTTPS"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_lb_tg.arn
  }
}

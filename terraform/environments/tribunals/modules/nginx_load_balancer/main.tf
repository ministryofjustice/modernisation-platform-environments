resource "aws_lb" "nginx_lb" {
  name               = "tribunals-nginx"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.nginx_lb_sg.id]
  subnets            = data.aws_subnets.shared-public.ids
}

resource "aws_lb_target_group" "nginx_lb_tg" {
  name     = "tribunals-nginx"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.shared.id
  health_check {
    matcher = "302"
  }
}

variable "nginx_instance_ids" {
  type = map(string)
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

resource "aws_security_group" "nginx_lb_sg" {
  name        = "nginx-lb-sg"
  description = "Allow all web access to nginx load balancer"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
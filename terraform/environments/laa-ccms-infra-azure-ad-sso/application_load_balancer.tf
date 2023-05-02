resource "aws_lb" "ebs_vision_db_lb" {
  depends_on = [
    aws_security_group.sg_ebs_vision_db_lb
  ]
  name               = lower(format("lb-%s-%s", substr(local.application_name, 0, 23), substr(local.environment, 0, 3)))
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_ebs_vision_db_lb.id]
  subnets            = data.aws_subnets.private-public.ids

  enable_deletion_protection = false

  access_logs {
    bucket  = module.s3-bucket-logging.bucket.id
    prefix  = local.lb_log_prefix
    enabled = true
  }

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-vision", local.application_name, local.environment)) }
  )
}

#
resource "aws_lb_target_group" "ebs_vision_db_tg_http" {
  depends_on = [aws_lb.ebs_vision_db_lb]
  name       = lower(format("tg-%s-%s", substr(local.application_name, 0, 23), substr(local.environment, 0, 3)))
  # not sure if this is the right port for the lb
  port     = 8000
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.shared.id
  health_check {
    port     = 8000
    protocol = "HTTP"
    path     = "/"
    timeout  = 2
    interval = 5
    matcher  = "200,301,302"
  }
}

resource "aws_lb_target_group_attachment" "ebs_vision_db_attachment" {
  target_group_arn = aws_lb_target_group.ebs_vision_db_tg_http.arn
  target_id        = aws_instance.ec2_oracle_vision_ebs.id
  port             = 8000
}

resource "aws_launch_template" "webgate_asg_tpl" {
  name_prefix            = lower(format("asg-tpl-%s-%s-Webgate", local.application_name, local.environment))
  image_id               = data.aws_ami.oracle_base_prereqs.id
  instance_type          = local.application_data.accounts[local.environment].ec2_oracle_instance_type_webgate
  key_name               = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg_oracle_base.id]
}
/*
resource "aws_autoscaling_group" "webgate_asg" {
  name_prefix         = "webgate-"
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  vpc_zone_identifier = [data.aws_subnet.private_subnets_a.id]

  launch_template {
    id      = aws_launch_template.webgate_asg_tpl.id
    version = "$Latest"
  }
}
*/
/*
resource "aws_lb" "webgate_alb" {
  #name               = lower(format("alb-%s-%s-Webgate", local.application_name, local.environment)) 
  internal                   = false
  load_balancer_type         = "application"
  enable_deletion_protection = true
  security_groups            = [aws_security_group.webgate-alb-sg.id]
  subnets = [data.aws_subnet.private_subnets_a.id,
    data.aws_subnet.private_subnets_a.id,
    data.aws_subnet.private_subnets_a.id
  ]
  
  #access_logs {
  #  bucket  = aws_s3_bucket.lb_logs.bucket
  #  prefix  = "webgate-lb"
  #  enabled = true
  #}
  
  tags = merge(local.tags,
    { Name = lower(format("alb-%s-%s-webgate", local.application_name, local.environment)) }
  )
}
*/


resource "aws_security_group" "webgate-alb-sg" {
  #name               = lower(format("sg-%s-%s-Webgate", local.application_name, local.environment)) 
  description = "allow HTTPS to Webgate ALB"
  vpc_id      = data.aws_vpc.shared.id
  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-webgate", local.application_name, local.environment)) }
  )
}

/*
resource "aws_autoscaling_attachment" "webgate_asg_att" {
  autoscaling_group_name = aws_autoscaling_group.webgate_asg.id
  lb_target_group_arn    = aws_alb_target_group.webgate_tg.arn
}
*/

resource "aws_alb_target_group" "webgate_tg" {
  name        = "webgate-targetgroup"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.shared.id
  target_type = "instance"
  /*
  health_check {
    interval            = 30
    path                = "/index.html"
    port                = 80
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200,202"
  }
*/
}

/*
resource "aws_alb_listener" "hhtps_webgate" {
  load_balancer_arn = aws_lb.webgate_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  default_action {
    target_group_arn = aws_alb_target_group.webgate_tg.arn
    type             = "forward"
  }
}
*/

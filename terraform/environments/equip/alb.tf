resource "aws_security_group" "alb" {
  name        = "terraform_alb_security_group"
  description = "Terraform load balancer security group"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    from_port   = 443
    to_port     = 443
    description = "Allow SSL Traffic"
    protocol    = "tcp"
    #tfsec:ignore:aws-vpc-no-public-ingress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    description = "Allow Non SSL Traffic"
    protocol    = "tcp"
    #tfsec:ignore:aws-vpc-no-public-ingress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    description = "Allow Egress Traffic"
    protocol    = "-1"
    #tfsec:ignore:aws-vpc-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-alb-security-group"
  }
}

##############################################################
# S3 Bucket Creation
# For root account id, refer below link
# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html
##############################################################

resource "aws_lb" "citrix_alb" {

  #checkov:skip=CKV2_AWS_28:
  #checkov:skip=CKV2_AWS_20

  name        = format("%s-alb", var.name)
  name_prefix = var.name_prefix

  load_balancer_type = var.load_balancer_type
  #tfsec:ignore:aws-elb-alb-not-public
  internal        = var.internal
  security_groups = [aws_security_group.alb.id]
  subnets         = [data.aws_subnet.public_az_a.id, data.aws_subnet.public_az_b.id]

  enable_deletion_protection       = var.enable_deletion_protection
  idle_timeout                     = var.idle_timeout
  enable_http2                     = var.enable_http2
  desync_mitigation_mode           = var.desync_mitigation_mode
  drop_invalid_header_fields       = var.drop_invalid_header_fields
  enable_waf_fail_open             = var.enable_waf_fail_open
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  ip_address_type                  = var.ip_address_type

  tags = merge(
    var.tags,
    var.lb_tags,
    {
      Name = var.name != null ? var.name : var.name_prefix
    },
  )

  access_logs {
    bucket = aws_s3_bucket.this.id
    #    prefix  = "access-logs-alb"
    enabled = "true"
  }

  depends_on = [aws_s3_bucket.this]

  timeouts {
    create = var.load_balancer_create_timeout
    update = var.load_balancer_update_timeout
    delete = var.load_balancer_delete_timeout
  }
}

resource "aws_lb_target_group" "lb_tg_http" {
  name             = "citrix-alb-tgt"
  target_type      = var.lb_tgt_target_type
  protocol         = var.lb_tgt_protocol
  protocol_version = var.lb_tgt_protocol_version
  vpc_id           = data.aws_vpc.shared.id
  port             = var.lb_tgt_port

  health_check {
    enabled             = true
    path                = var.lb_tgt_health_check_path
    interval            = 30
    protocol            = "HTTP"
    port                = 80
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = var.lb_tgt_matcher
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}


#tfsec:ignore:aws-elb-http-not-used
resource "aws_lb_listener" "lb_listener_http" {
  load_balancer_arn = aws_lb.citrix_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.lb_tg_http.id
    type             = "forward"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group_attachment" "citrix_instance" {
  target_group_arn = aws_lb_target_group.lb_tg_http.arn
  target_id        = aws_instance.citrix_adc_instance.id
  port             = 80
}

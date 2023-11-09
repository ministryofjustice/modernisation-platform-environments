# Load balancer build using the module
module "lb_access_logs_enabled" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer?ref=f1d5f9dfc2df68f01ba46ec1dd0ab5377a0db6e9" # v3.3.1
  providers = {
    # Here we use the default provider for the S3 bucket module, buck replication is disabled but we still
    # Need to pass the provider to the S3 bucket module
    aws.bucket-replication = aws
  }
  vpc_all = "${local.vpc_name}-${local.environment}"
  #existing_bucket_name               = "my-bucket-name"
  force_destroy_bucket       = true # enables destruction of logging bucket
  application_name           = local.application_name
  public_subnets             = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id] // private subnets
  loadbalancer_ingress_rules = local.loadbalancer_ingress_rules
  loadbalancer_egress_rules  = local.loadbalancer_egress_rules
  tags                       = local.tags
  account_number             = local.environment_management.account_ids[terraform.workspace]
  region                     = "eu-west-2"
  enable_deletion_protection = false
  idle_timeout               = 60
  internal_lb                = true // create internal facing ALB
}

# Create the target group
resource "aws_lb_target_group" "target_group_module" {
  name                 = "${local.application_name}-tg-mlb-${local.environment}-HTTP"
  port                 = local.application_data.accounts[local.environment].server_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }
  #checkov:skip=CKV_AWS_261: "health_check defined below, but not picked up"
  health_check {
    healthy_threshold   = "5"
    interval            = "120"
    protocol            = "HTTP"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "5"
  }
}

resource "aws_lb_target_group" "target_group_module_HTTPS" {
  name                 = "${local.application_name}-tg-mlb-${local.environment}-HTTPS"
  port                 = "443"
  protocol             = "HTTPS"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }
  #checkov:skip=CKV_AWS_261: "health_check defined below, but not picked up"
  health_check {
    healthy_threshold   = "5"
    interval            = "120"
    protocol            = "HTTPS"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "5"
  }
}

# Register nginx instance to target group
resource "aws_lb_target_group_attachment" "register_nginx_server_http" {
  target_group_arn = aws_lb_target_group.target_group_module.arn
  target_id        = module.ec2_test_instance["nginx_server"].aws_instance.id 
  port             = 80
}

resource "aws_lb_target_group_attachment" "register_nginx_server_https" {
  target_group_arn = aws_lb_target_group.target_group_module_HTTPS.arn
  target_id        = module.ec2_test_instance["nginx_server"].aws_instance.id 
  port             = 443
}

# Create Listeners
resource "aws_lb_listener" "nginx_listener_http" {
  load_balancer_arn = module.lb_access_logs_enabled.load_balancer_arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_module.arn
  }
}

resource "aws_lb_listener" "nginx_listener_https" {
  load_balancer_arn = module.lb_access_logs_enabled.load_balancer_arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.example_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_module_HTTPS.arn
  }
}
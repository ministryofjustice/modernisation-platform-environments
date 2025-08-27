locals {
  lb_name     = "${var.env_name}-dfi-elb"
  lb_endpoint = "ndl_dfi"
}

# Implement classic load balancer as per legacy MIS environment
resource "aws_elb" "dfi" {
  count           = var.lb_config != null ? 1 : 0
  name            = local.lb_name
  subnets         = var.account_config.public_subnet_ids
  internal        = false
  security_groups = [aws_security_group.mis_ec2_shared.id]

  cross_zone_load_balancing   = true
  idle_timeout                = 300
  connection_draining         = false
  connection_draining_timeout = 300

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 443
    lb_protocol       = "https"
  }

  access_logs {
    bucket        = module.s3_lb_logs_bucket[0].bucket.id
    bucket_prefix = local.lb_name
    interval      = 60
  }

  health_check {
    target              = "HTTP:8080/DataServices/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  tags = merge(
    local.tags,
    {
      "Name" = format("%s", local.lb_name)
    },
  )
}

# Attach DFI instances to the load balancer
resource "aws_elb_attachment" "dfi_attachment" {
  count    = var.lb_config != null && var.dfi_config != null ? var.dfi_config.instance_count : 0
  elb      = aws_elb.dfi[0].id
  instance = module.dfi_instance[count.index].aws_instance.id
}

resource "aws_lb_cookie_stickiness_policy" "dfi_stickiness" {
  count         = var.lb_config != null ? 1 : 0
  name          = "dfi-policy"
  load_balancer = aws_elb.dfi[0].id
  lb_port       = 443
}

# Create route53 entry for lb
resource "aws_route53_record" "dfi_entry" {
  count    = var.lb_config != null ? 1 : 0
  provider = aws.core-vpc

  zone_id = var.account_config.route53_external_zone.zone_id
  name    = "${local.lb_endpoint}.${var.env_name}.${var.account_config.dns_suffix}"
  type    = "A"

  alias {
    name                   = aws_elb.dfi[0].dns_name
    zone_id                = aws_elb.dfi[0].zone_id
    evaluate_target_health = false
  }
}

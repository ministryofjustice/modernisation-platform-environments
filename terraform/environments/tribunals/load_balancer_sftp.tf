locals {
  target_group_arns_sftp = { for k, v in aws_lb_target_group.tribunals_target_group_sftp : k => v.arn }
}

# tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "tribunals_lb_sftp" {
  #checkov:skip=CKV_AWS_91:"Access logging not required for this SFTP load balancer"
  #checkov:skip=CKV_AWS_152:"Cross-zone load balancing not needed for this deployment"enable_deletion_protection = true
  #tfsec:ignore:AVD-AWS-0053
  name                       = "tribunals-sftp-lb"
  load_balancer_type         = "network"
  security_groups            = [aws_security_group.tribunals_lb_sc_sftp.id]
  subnets                    = data.aws_subnets.shared-public.ids
  enable_deletion_protection = true
}

resource "aws_security_group" "tribunals_lb_sc_sftp" {
  #checkov:skip=CKV_AWS_382:"Full egress access required for SFTP connections"
  #checkov:skip=CKV_AWS_260:"Public access required for SFTP service"
  name        = "tribunals-load-balancer-sg-sftp"
  description = "control access to the network load balancer for sftp"
  vpc_id      = data.aws_vpc.shared.id
  dynamic "ingress" {
    for_each = {
      for k, v in var.sftp_services : k => v if v.upload_enabled
    }
    content {
      description = "allow all traffic on port ${ingress.value.sftp_port}"
      from_port   = ingress.value.sftp_port
      to_port     = ingress.value.sftp_port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    description = "allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_listener" "tribunals_lb_sftp" {
  for_each          = var.sftp_services
  load_balancer_arn = aws_lb.tribunals_lb_sftp.arn
  port              = each.value.sftp_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tribunals_target_group_sftp[each.key].arn
  }
}

resource "aws_lb_target_group" "tribunals_target_group_sftp" {
  for_each             = var.sftp_services
  name                 = "${each.value.name_prefix}-sftp-tg"
  port                 = each.value.sftp_port
  protocol             = "TCP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    healthy_threshold   = "3"
    interval            = "15"
    protocol            = "TCP"
    unhealthy_threshold = "3"
    timeout             = "10"
  }
}

# Make sure that the ec2 instance tagged as 'tribunals-instance' exists
# before adding aws_lb_target_group_attachment, otherwise terraform will fail
resource "aws_lb_target_group_attachment" "tribunals_target_group_attachment_sftp" {
  for_each         = aws_lb_target_group.tribunals_target_group_sftp
  target_group_arn = each.value.arn
  # target_id points to primary ec2 instance, change "primary_instance" to "backup_instance" in order to point at backup ec2 instance
  target_id = data.aws_instances.primary_instance.ids[0]
  port      = each.value.port

  depends_on = [data.aws_instances.primary_instance]
}

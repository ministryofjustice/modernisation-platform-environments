module "ecs" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs?ref=e57c01f26ddc488fe6c83bfdc2817510f44f3b19"

  subnet_set_name         = local.subnet_set_name
  vpc_all                 = local.vpc_all
  app_name                = local.application_name
  container_instance_type = local.app_data.accounts[local.environment].container_instance_type
  environment             = local.environment
  ami_image_id            = data.aws_ami.latest.image_id
  instance_type           = local.app_data.accounts[local.environment].instance_type
  user_data               = base64encode(data.template_file.launch-template.rendered)
  key_name                = local.app_data.accounts[local.environment].key_name
  task_definition         = data.template_file.task_definition.rendered
  ec2_desired_capacity    = local.app_data.accounts[local.environment].ec2_desired_capacity
  ec2_max_size            = local.app_data.accounts[local.environment].ec2_max_size
  ec2_min_size            = local.app_data.accounts[local.environment].ec2_min_size
  appscaling_min_capacity = local.app_data.accounts[local.environment].appscaling_min_capacity
  container_cpu           = local.app_data.accounts[local.environment].container_cpu
  container_memory        = local.app_data.accounts[local.environment].container_memory
  task_definition_volume  = local.app_data.accounts[local.environment].task_definition_volume
  network_mode            = local.app_data.accounts[local.environment].network_mode
  server_port             = local.app_data.accounts[local.environment].server_port
  app_count               = local.app_data.accounts[local.environment].app_count
  ec2_ingress_rules       = local.ec2_ingress_rules
  ec2_egress_rules        = local.ec2_egress_rules
  tags_common             = local.tags

  depends_on = [aws_security_group.load_balancer_security_group, aws_lb_target_group.target_group]
}

data "aws_ami" "latest" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Core-ECS_Optimized-*"]
  }
}
data "aws_vpc" "shared" {
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}"
  }
}

data "aws_subnets" "shared-public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public*"
  }
}

data "aws_route53_zone" "network-services" {
  provider = aws.core-network-services

  name         = "modernisation-platform.service.justice.gov.uk."
  private_zone = false
}

data "template_file" "task_definition" {
  template = file("templates/task_definition.json")
}

data "template_file" "launch-template" {
  template = file("templates/user-data.txt")
  vars = {
    cluster_name = local.application_name
  }
}

data "aws_route53_zone" "external" {
  provider = aws.core-vpc

  name         = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk."
  private_zone = false
}

resource "aws_acm_certificate" "external" {
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = ["*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "external_validation" {
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.domain_name_main[0]
  records         = local.domain_record_main
  ttl             = 60
  type            = local.domain_type_main[0]
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

resource "aws_route53_record" "external_validation_subdomain" {
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.domain_name_sub[0]
  records         = local.domain_record_sub
  ttl             = 60
  type            = local.domain_type_sub[0]
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0]]
}

#------------------------------------------------------------------------------
# Load Balancer
#------------------------------------------------------------------------------
#tfsec:ignore:AWS005 tfsec:ignore:AWS083

resource "aws_lb_target_group" "target_group" {
  #checkov:skip=CKV_AWS_261
  name                 = "${local.application_name}-tg-${local.environment}"
  port                 = local.app_data.accounts[local.environment].server_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    # path                = "/"
    healthy_threshold   = "5"
    interval            = "120"
    protocol            = "HTTP"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "5"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-tg-${local.environment}"
    }
  )
}

resource "aws_security_group" "load_balancer_security_group" {
  name_prefix = "${local.application_name}-loadbalancer-security-group"
  description = "controls access to lb"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    protocol    = "tcp"
    description = "Open the server port"
    from_port   = local.app_data.accounts[local.environment].server_port
    to_port     = local.app_data.accounts[local.environment].server_port
    #tfsec:ignore:AWS008
    cidr_blocks = ["0.0.0.0/0", ]
  }

  ingress {
    protocol    = "tcp"
    description = "Open the SSL port"
    from_port   = 443
    to_port     = 443
    #tfsec:ignore:AWS008
    cidr_blocks = ["0.0.0.0/0", ]
  }

  egress {
    protocol    = "-1"
    description = "Open all outbound ports"
    from_port   = 0
    to_port     = 0
    #tfsec:ignore:AWS009
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-loadbalancer-security-group"
    }
  )
}

resource "aws_lb" "external" {
  #tfsec:ignore:AWS005
  #tfsec:ignore:AWS083
  #checkov:skip=CKV_AWS_91
  #checkov:skip=CKV_AWS_131
  #checkov:skip=CKV2_AWS_20
  #checkov:skip=CKV2_AWS_28
  #checkov:skip=CKV_AWS_150
  name                       = "${local.application_name}-loadbalancer"
  load_balancer_type         = "application"
  subnets                    = data.aws_subnets.shared-public.ids
  enable_deletion_protection = false
  # allow 60*4 seconds before 504 gateway timeout for long-running DB operations
  idle_timeout = 240

  security_groups = [aws_security_group.load_balancer_security_group.id]

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-external-loadbalancer"
    }
  )
}

#tfsec:ignore:AWS004
resource "aws_lb_listener" "listener" {
  #checkov:skip=CKV_AWS_2
  #checkov:skip=CKV_AWS_103
  load_balancer_arn = aws_lb.external.id
  port              = local.app_data.accounts[local.environment].server_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target_group.id
    type             = "forward"
  }
}

resource "aws_key_pair" "testing-test" {
  key_name   = "testing-test"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCnSAEpvC64hz/xAuzE2ruHVFVCXoHTxSYQDW3hmDTPAO+lcHiMuxWZVyHlGl8sjdIr0uY9vvuIyXaiCmLRon4EppIua+N9WqXpg2W8zEvsWxeJJOLRqkp0kv3XttKAQ4a2u/nbiQO11ylEfsPMKjGrCPTkWvpC0XrGbEKGyCM4ep7oaiFn2CGXZxy7ZkBru39Fz5LCG8tWmlND4TNeUm1x0WkX2t+r5hSkHRedcGtF6dCayAfG/zZ6i8FmHX8HC2KYudAvUa4eLQkLvwfZufDiEtVaxUvpnPP1+tWn1OxqzYvIT69DLTXFWXRxtSclb3ybV2J3Khiki+TKP/LUK1/4ezGDIUWH0pyG5r0yWfDzvJKtHyJqJMQ+szQoVE38xxHTWxRf04KbYfJvlUzp0Bj4wrQ+NLDkjx2qYRjanzGHXLL/J1V5UwHrTFqOeA1R0Ek+nqs4+v9tUK1oOrnUAXC94Nr/VVgKma/KMnwPf2Ij+knaMVq4iIRHrckRulO6KS0= zuri@ZuriGuardiolasMacbookpro.local"
}

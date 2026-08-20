##############################################
### ECS Fargate — LinOTP 3.x + FreeRADIUS
###
### Parallel deployment alongside EC2 stack.
### EC2 remains the active RADIUS server until
### manual switchover via new-adds-radius.tf.
##############################################

##############################################
### Data Sources — Existing Secrets
##############################################

data "aws_secretsmanager_secret" "ad_admin_password" {
  name  = "${local.application_name}/${local.environment}/ad-admin-password"
}

##############################################
### LinOTP Encryption Key (must persist across task restarts)
##############################################

resource "random_id" "linotp3_enc_key" {
  byte_length = 32
}

resource "aws_secretsmanager_secret" "linotp3_enc_key" {
  name                    = "${local.application_name}/${local.environment}/linotp3-enc-key"
  description             = "LinOTP 3.x AES encryption key — must not change after first token enrollment"
  recovery_window_in_days = 0

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}/${local.environment}/linotp3-enc-key" }
  )
}

resource "aws_secretsmanager_secret_version" "linotp3_enc_key" {
  secret_id     = aws_secretsmanager_secret.linotp3_enc_key.id
  secret_string = random_id.linotp3_enc_key.hex

  lifecycle {
    ignore_changes = [secret_string]
  }
}

##############################################
### Security Group — ECS Tasks
##############################################

resource "aws_security_group" "ecs_linotp3" {
  name_prefix = "lnw-${local.environment}-ecs-linotp3-"
  description = "ECS Fargate tasks: LinOTP 3.x (port 5000) + FreeRADIUS (1812/1813 UDP)"
  vpc_id      = aws_vpc.workspaces.id

  revoke_rules_on_delete = true

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-ecs-linotp3" }
  )
}

resource "aws_security_group_rule" "ecs_linotp3_ingress_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.ecs_linotp3.id
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.radius_alb.id
  description              = "LinOTP HTTP from ALB"
}

resource "aws_security_group_rule" "ecs_linotp3_ingress_nlb_healthcheck" {
  type              = "ingress"
  security_group_id = aws_security_group.ecs_linotp3.id
  from_port         = 5000
  to_port           = 5000
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.workspaces.cidr_block]
  description       = "LinOTP HTTP from NLB (health checks)"
}

resource "aws_security_group_rule" "ecs_linotp3_ingress_radius_auth" {
  type              = "ingress"
  security_group_id = aws_security_group.ecs_linotp3.id
  from_port         = 1812
  to_port           = 1812
  protocol          = "udp"
  cidr_blocks       = [aws_vpc.workspaces.cidr_block]
  description       = "RADIUS auth from VPC"
}

resource "aws_security_group_rule" "ecs_linotp3_ingress_radius_accounting" {
  type              = "ingress"
  security_group_id = aws_security_group.ecs_linotp3.id
  from_port         = 1813
  to_port           = 1813
  protocol          = "udp"
  cidr_blocks       = [aws_vpc.workspaces.cidr_block]
  description       = "RADIUS accounting from VPC"
}

resource "aws_security_group_rule" "ecs_linotp3_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.ecs_linotp3.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

##############################################
### IAM — ECS Task Execution Role
### (Used by ECS to pull images and inject secrets)
##############################################

resource "aws_iam_role" "ecs_task_execution" {
  name_prefix = "lnw-${local.environment}-ecs-exec-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-ecs-task-execution-role" }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {

  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name = "lnw-${local.environment}-ecs-secrets"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsInjection"
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          aws_secretsmanager_secret.linotp3_enc_key.arn,
          aws_secretsmanager_secret.linotp3_db_password.arn,
          aws_secretsmanager_secret.linotp_admin_password.arn,
          aws_secretsmanager_secret.radius_shared_secret.arn,
          data.aws_secretsmanager_secret.ad_admin_password.arn,
        ]
      }
    ]
  })
}

##############################################
### ALB Target Group + Listener Rule for LinOTP 3.x Portal
##############################################

resource "aws_lb_target_group" "linotp3_portal" {
  name_prefix = "lntp3-"
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.workspaces.id

  health_check {
    enabled             = true
    path                = "/manage/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-linotp3-portal" }
  )
}

resource "aws_lb_listener_rule" "linotp3_portal" {
  listener_arn = aws_lb_listener.radius_https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.linotp3_portal.arn
  }

  condition {
    host_header {
      values = ["mfa-portal.${trimsuffix(data.aws_route53_zone.external.name, ".")}"]
    }
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-linotp3-portal-rule" }
  )
}

resource "aws_route53_record" "linotp3_portal" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "mfa-portal.${data.aws_route53_zone.external.name}"
  type     = "A"

  alias {
    name                   = aws_lb.radius_portal.dns_name
    zone_id                = aws_lb.radius_portal.zone_id
    evaluate_target_health = true
  }
}

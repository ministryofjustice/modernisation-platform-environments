##############################################
### ECS Fargate — LinOTP 3.x + FreeRADIUS
###
### Parallel deployment alongside EC2 stack.
### EC2 remains the active RADIUS server until
### manual switchover via new-adds-radius.tf.
##############################################

##############################################
### LinOTP Encryption Key (must persist across task restarts)
##############################################

resource "random_id" "linotp3_enc_key" {
  count = local.environment == "development" ? 1 : 0

  byte_length = 32
}

resource "aws_secretsmanager_secret" "linotp3_enc_key" {
  count = local.environment == "development" ? 1 : 0

  name                    = "${local.application_name}/${local.environment}/linotp3-enc-key"
  description             = "LinOTP 3.x AES encryption key — must not change after first token enrollment"
  recovery_window_in_days = 0

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}/${local.environment}/linotp3-enc-key" }
  )
}

resource "aws_secretsmanager_secret_version" "linotp3_enc_key" {
  count = local.environment == "development" ? 1 : 0

  secret_id     = aws_secretsmanager_secret.linotp3_enc_key[0].id
  secret_string = random_id.linotp3_enc_key[0].hex

  lifecycle {
    ignore_changes = [secret_string]
  }
}

##############################################
### Security Group — ECS Tasks
##############################################

resource "aws_security_group" "ecs_linotp3" {
  count = local.environment == "development" ? 1 : 0

  name_prefix = "${local.application_name}-${local.environment}-ecs-linotp3-"
  description = "ECS Fargate tasks: LinOTP 3.x (port 80) + FreeRADIUS (1812/1813 UDP)"
  vpc_id      = aws_vpc.workspaces[0].id

  ingress {
    description     = "LinOTP HTTP from ALB"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.radius_alb[0].id]
  }

  ingress {
    description = "LinOTP HTTP from NLB (health checks)"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.workspaces[0].cidr_block]
  }

  ingress {
    description = "RADIUS auth from VPC"
    from_port   = 1812
    to_port     = 1812
    protocol    = "udp"
    cidr_blocks = [aws_vpc.workspaces[0].cidr_block]
  }

  ingress {
    description = "RADIUS accounting from VPC"
    from_port   = 1813
    to_port     = 1813
    protocol    = "udp"
    cidr_blocks = [aws_vpc.workspaces[0].cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-ecs-linotp3" }
  )
}

##############################################
### IAM — ECS Task Execution Role
### (Used by ECS to pull images and inject secrets)
##############################################

resource "aws_iam_role" "ecs_task_execution" {
  count = local.environment == "development" ? 1 : 0

  name_prefix = "${local.application_name}-${local.environment}-ecs-exec-"

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
  count = local.environment == "development" ? 1 : 0

  role       = aws_iam_role.ecs_task_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  count = local.environment == "development" ? 1 : 0

  name = "${local.application_name}-${local.environment}-ecs-exec-secrets"
  role = aws_iam_role.ecs_task_execution[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsInjection"
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          aws_secretsmanager_secret.linotp3_enc_key[0].arn,
          aws_secretsmanager_secret.linotp3_db_password[0].arn,
          aws_secretsmanager_secret.linotp_admin_password[0].arn,
          aws_secretsmanager_secret.radius_shared_secret[0].arn,
          aws_secretsmanager_secret.linotp_ad_bind_password[0].arn,
        ]
      }
    ]
  })
}

##############################################
### ALB Target Group + Listener Rule for LinOTP 3.x Portal
##############################################

resource "aws_lb_target_group" "linotp3_portal" {
  count = local.environment == "development" ? 1 : 0

  name_prefix = "lntp3-"
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.workspaces[0].id

  health_check {
    enabled             = true
    path                = "/"
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
  count = local.environment == "development" ? 1 : 0

  listener_arn = aws_lb_listener.radius_https[0].arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.linotp3_portal[0].arn
  }

  condition {
    host_header {
      values = ["workspace-mfa-ecs.${trimsuffix(data.aws_route53_zone.external.name, ".")}"]
    }
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-linotp3-portal-rule" }
  )
}

resource "aws_route53_record" "linotp3_portal" {
  count = local.environment == "development" ? 1 : 0

  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "workspace-mfa-ecs.${data.aws_route53_zone.external.name}"
  type     = "A"

  alias {
    name                   = aws_lb.radius_portal[0].dns_name
    zone_id                = aws_lb.radius_portal[0].zone_id
    evaluate_target_health = true
  }
}

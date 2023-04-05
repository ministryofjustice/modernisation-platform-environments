variable "region" {
  type        = string
  description = ""
  default     = "eu-west-2"
}
# data "aws_iam_policy_document" "assume_policy_document" {
#   statement {
#     actions = [
#       "sts:AssumeRole"
#     ]
#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "bastion_host_role" {
#   name               = "bastion_linux_ec2_role"
#   path               = "/"
#   assume_role_policy = data.aws_iam_policy_document.assume_policy_document.json

#   tags = merge(
#     local.tags,
#     {
#       Name = "bastion_linux_ec2_role"
#     },
#   )

# }

# resource "aws_iam_role_policy_attachment" "bastion_host_ssm" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   role       = aws_iam_role.bastion_host_role.name
# }

# data "aws_iam_policy_document" "bastion_ssm_s3_policy_document" {

#   statement {
#     effect = "Allow"
#     actions = [
#       "s3:GetObject"
#     ]
#     resources = [
#       "arn:aws:s3:::aws-ssm-${var.region}/*",
#       "arn:aws:s3:::aws-windows-downloads-${var.region}/*",
#       "arn:aws:s3:::amazon-ssm-${var.region}/*",
#       "arn:aws:s3:::amazon-ssm-packages-${var.region}/*",
#       "arn:aws:s3:::${var.region}-birdwatcher-prod/*",
#       "arn:aws:s3:::aws-ssm-distributor-file-${var.region}/*",
#       "arn:aws:s3:::aws-ssm-document-attachments-${var.region}/*",
#       "arn:aws:s3:::patch-baseline-snapshot-${var.region}/*"
#     ]
#   }
# }
# resource "aws_iam_policy" "bastion_ssm_s3_policy" {
#   name   = "bastion_ssm_s3"
#   policy = data.aws_iam_policy_document.bastion_ssm_s3_policy_document.json
# }

# resource "aws_iam_role_policy_attachment" "bastion_host_ssm_s3" {
#   policy_arn = aws_iam_policy.bastion_ssm_s3_policy.arn
#   role       = aws_iam_role.bastion_host_role.name
# }

# resource "aws_iam_instance_profile" "bastion_host_profile" {
#   role = aws_iam_role.bastion_host_role.name
#   path = "/"
# }

#------------------------------------------------------------------------------
# Application - ECS Fargate
#------------------------------------------------------------------------------

resource "aws_security_group" "app" {

  name        = "app-${var.networking[0].application}"
  description = "Allow traffic from load balancer(s)"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      Name = "app-${var.networking[0].application}"
    },
  )
}

#tfsec:ignore:aws-vpc-no-public-egress-sgr
resource "aws_security_group_rule" "app_egress_1" {

  security_group_id = aws_security_group.app.id
  description       = "Allow app servers unrestricted internet access"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_ingress_1" {

  security_group_id        = aws_security_group.app.id
  description              = "Allow external lb to send traffic in to application sg"
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.external_lb.id
}

resource "aws_security_group_rule" "app_ingress_2" {

  security_group_id        = aws_security_group.app.id
  description              = "Allow internal lb to send traffic in to application sg"
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.inner_lb.id
}

# tfsec:ignore:aws-ecs-enable-container-insight
resource "aws_ecs_cluster" "app" {
  # checkov:skip=CKV_AWS_65
  name = var.networking[0].application
  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = merge(
    local.tags,
    {
      Name = var.networking[0].application
    },
  )
}

resource "aws_ecs_service" "app" {
  depends_on = [
    aws_lb_target_group.external,
    aws_lb_target_group.inner,
    aws_lb_listener.external,
    aws_lb_listener.inner
  ]

  name = var.networking[0].application
  deployment_controller {
    type = "ECS"
  }
  cluster                           = aws_ecs_cluster.app.id
  task_definition                   = aws_ecs_task_definition.app.arn
  launch_type                       = local.application_data.accounts[local.environment].ecs_type
  enable_execute_command            = true
  desired_count                     = "1"
  health_check_grace_period_seconds = "120"
  network_configuration {
    subnets          = data.aws_subnets.private-public.ids
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.external.arn
    container_name   = var.networking[0].application
    container_port   = 3000
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.inner.arn
    container_name   = var.networking[0].application
    container_port   = 3000
  }

  tags = merge(
    local.tags,
    {
      Name = var.networking[0].application
    },
  )
}

resource "aws_ecs_task_definition" "app" {

  network_mode             = "awsvpc"
  requires_compatibilities = [local.application_data.accounts[local.environment].ecs_type]
  execution_role_arn       = aws_iam_role.app_execution.arn
  task_role_arn            = aws_iam_role.app_task.arn
  family                   = var.networking[0].application
  cpu                      = 256
  memory                   = 1024
  container_definitions    = <<TASK_DEFINITION
  [
    {
      "name": "${var.networking[0].application}",
      "image": "${local.environment_management.account_ids[terraform.workspace]}.dkr.ecr.eu-west-2.amazonaws.com/testlab:latest",
      "cpu": 256,
      "memory": 1024,
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000
        }
      ],
      "LogConfiguration": {
        "LogDriver": "awslogs",
        "Options": {
          "awslogs-group": "${var.networking[0].application}",
          "awslogs-region": "eu-west-2",
          "awslogs-stream-prefix": "${var.networking[0].application}"
        }
      },
      "environment" : [
        {
          "name" : "DB_HOST",
          "value" : "${aws_db_instance.app.address}"
        },
        {
          "name" : "DB_SCHEMA",
          "value": "${var.networking[0].application}"
        },
        {
          "name" : "DB_USER",
          "value" : "dbmain"
        },
        {
          "name" : "DB_PORT",
          "value" : "5432"
        }
      ],
      "secrets": [
        {
          "name": "DB_PASSWORD",
          "valueFrom": "${aws_secretsmanager_secret_version.master_password.arn}"
        }
      ]
    }
  ]
  TASK_DEFINITION

  tags = merge(
    local.tags,
    {
      Name = var.networking[0].application
    },
  )
}

resource "aws_iam_role" "app_execution" {
  name = "execution-${var.networking[0].application}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(
    local.tags,
    {
      Name = "execution-${var.networking[0].application}"
    },
  )
}

resource "aws_iam_role_policy" "app_execution" {
  name = "execution-${var.networking[0].application}"
  role = aws_iam_role.app_execution.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
           "Action": [
               "logs:CreateLogStream",
               "logs:PutLogEvents",
               "ecr:GetAuthorizationToken"
           ],
           "Resource": "*",
           "Effect": "Allow"
      },
      {
            "Action": [
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage"
            ],
              "Resource": "arn:aws:ecr:*:${local.environment_management.account_ids[terraform.workspace]}:repository/testlab",
            "Effect": "Allow"
      },
      {
          "Action": [
               "secretsmanager:GetSecretValue"
           ],
          "Resource": "arn:aws:secretsmanager:*:${local.environment_management.account_ids[terraform.workspace]}:secret:${var.networking[0].application}-db-master-*",
          "Effect": "Allow"
      }
    ]
  }
  EOF
}

resource "aws_iam_role" "app_task" {
  name = "task-${var.networking[0].application}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(
    local.tags,
    {
      Name = "task-${var.networking[0].application}"
    },
  )
}

resource "aws_iam_role_policy" "app_task" {
  name = "task-${var.networking[0].application}"
  role = aws_iam_role.app_task.id

  policy = <<-EOF
  {
   "Version": "2012-10-17",
   "Statement": [
     {
       "Effect": "Allow",
       "Action": [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
       ],
       "Resource": "*"
     }
   ]
  }
  EOF
}

#------------------------------------------------------------------------------
# Load Balancer - External
#------------------------------------------------------------------------------

resource "aws_security_group" "external_lb" {

  name        = "external-lb-${var.networking[0].application}"
  description = "Allow inbound traffic to external load balancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      Name = "external-lb-${var.networking[0].application}"
    },
  )
}

resource "aws_security_group_rule" "external_lb_ingress_1" {

  security_group_id = aws_security_group.external_lb.id
  description       = "Allow HTTP traffic in from internet endpoint"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks = [
    "81.157.202.5/32"
  ]
}

resource "aws_security_group_rule" "external_lb_egress_1" {

  security_group_id        = aws_security_group.external_lb.id
  description              = "Allow external lb to send traffic to application"
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "external_lb_ingress_2" {

  security_group_id = aws_security_group.external_lb.id
  description       = "Allow https traffic from internet"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks = [
    "35.176.93.186/32"
  ]
}

# tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "external" {
  # checkov:skip=CKV_AWS_91: "Sprinkler is minimally exposed to the internet so no real requirement for access logs"
  # checkov:skip=CKV_AWS_150: "Deletion protection not required for sprinkler"
  # checkov:skip=CKV2_AWS_28: "AWS Shield provides WAF by default"
  name                       = "external-${var.networking[0].application}"
  drop_invalid_header_fields = true
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.external_lb.id]
  subnets                    = data.aws_subnets.shared-public.ids
  enable_deletion_protection = false

  tags = merge(
    local.tags,
    {
      Name = "external-${var.networking[0].application}"
    },
  )
}

resource "aws_lb_target_group" "external" {
  # checkov:skip=CKV_AWS_261 "Health check clearly defined"
  name                 = "external-${var.networking[0].application}"
  port                 = "3000"
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = "30"
  vpc_id               = data.aws_vpc.shared.id

  health_check {
    enabled             = true
    healthy_threshold   = "5"
    interval            = "30"
    port                = "3000"
    protocol            = "HTTP"
    timeout             = "5"
    unhealthy_threshold = "2"
  }

  tags = merge(
    local.tags,
    {
      Name = "external-${var.networking[0].application}"
    },
  )
}

resource "aws_lb_listener" "external" {
  # checkov:skip=CKV_AWS_103: "LB using higher version of TLS"
  depends_on = [
    aws_acm_certificate_validation.external
  ]

  load_balancer_arn = aws_lb.external.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.external.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external.arn
  }
}

resource "aws_route53_record" "external" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${var.networking[0].application}.${var.networking[0].business-unit}-sandbox.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.external.dns_name
    zone_id                = aws_lb.external.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "external" {
  domain_name       = "${var.networking[0].business-unit}-sandbox.modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = ["*.${var.networking[0].business-unit}-sandbox.modernisation-platform.service.justice.gov.uk"]
  tags = {
    Environment = "test"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "external_validation" {
  provider = aws.core-vpc
  for_each = {
    for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [for record in aws_route53_record.external_validation : record.fqdn]
}

#------------------------------------------------------------------------------
# Load Balancer - inner
#------------------------------------------------------------------------------

resource "aws_security_group" "inner_lb" {

  name        = "inner-lb-${var.networking[0].application}"
  description = "Allow inbound traffic to inner load balancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      Name = "inner-lb-${var.networking[0].application}"
    },
  )
}

resource "aws_security_group_rule" "inner_lb_ingress_1" {

  security_group_id        = aws_security_group.inner_lb.id
  description              = "Allow inner lb to receive https traffic"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.inner_lb.id
}

resource "aws_security_group_rule" "inner_lb_egress_1" {

  security_group_id        = aws_security_group.inner_lb.id
  description              = "Allow inner lb to forward traffic to app sg on port tcp/3000"
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
}

resource "aws_lb" "inner" {
  # checkov:skip=CKV_AWS_91: "Sprinkler is minimally exposed to the internet so no real requirement for access logs"
  # checkov:skip=CKV_AWS_150: "Deletion protection not required for sprinkler"
  # checkov:skip=CKV2_AWS_28: "AWS Shield provides WAF by default"

  name                       = "inner-${var.networking[0].application}"
  drop_invalid_header_fields = true
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.inner_lb.id]
  subnets                    = data.aws_subnets.private-public.ids
  enable_deletion_protection = false

  tags = merge(
    local.tags,
    {
      Name = "inner-${var.networking[0].application}"
    },
  )
}

resource "aws_lb_target_group" "inner" {
  # checkov:skip=CKV_AWS_261 "Health check clearly defined"
  name                 = "inner-${var.networking[0].application}"
  port                 = "3000"
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = "30"
  vpc_id               = data.aws_vpc.shared.id

  health_check {
    enabled             = true
    healthy_threshold   = "5"
    interval            = "30"
    port                = "3000"
    protocol            = "HTTP"
    timeout             = "5"
    unhealthy_threshold = "2"
  }

  tags = merge(
    local.tags,
    {
      Name = "inner-${var.networking[0].application}"
    },
  )
}

resource "aws_lb_listener" "inner" {
  # checkov:skip=CKV_AWS_103: "LB using higher version of TLS"
  depends_on = [
    aws_acm_certificate.inner
  ]

  load_balancer_arn = aws_lb.inner.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.inner.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.inner.arn
  }
}

resource "aws_route53_record" "inner" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.inner.zone_id
  name    = "${var.networking[0].application}.${var.networking[0].business-unit}-sandbox.modernisation-platform.internal"
  type    = "A"

  alias {
    name                   = aws_lb.inner.dns_name
    zone_id                = aws_lb.inner.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "inner" {
  domain_name               = "${var.networking[0].business-unit}-sandbox.modernisation-platform.internal"
  certificate_authority_arn = local.is_live[0] == "live" ? data.terraform_remote_state.core_network_services.outputs.acmpca_subordinate_live : data.terraform_remote_state.core_network_services.outputs.acmpca_subordinate_non_live

  subject_alternative_names = ["*.${var.networking[0].business-unit}-sandbox.modernisation-platform.internal"]
  tags = {
    Environment = "test"
  }
  lifecycle {
    create_before_destroy = true
  }
}

#------------------------------------------------------------------------------
# Database
#------------------------------------------------------------------------------
resource "aws_security_group" "rds" {

  name        = "db-${var.networking[0].application}"
  description = "RDS security group"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      Name = "db-${var.networking[0].application}"
    },
  )
}

resource "aws_security_group_rule" "rds_ingress_1" {

  security_group_id        = aws_security_group.rds.id
  description              = "Allow traffic in from application security group for postgres"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "rds_egress_1" {

  security_group_id = aws_security_group.rds.id
  description       = "Allow RDS out to MP Dev & Test"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["10.26.0.0/16"]
}

resource "aws_db_subnet_group" "app" {

  name        = var.networking[0].application
  description = "Data subnets group"
  subnet_ids  = data.aws_subnets.shared-data.ids

  tags = merge(
    local.tags,
    {
      Name = var.networking[0].application
    },
  )
}

# Create and store database secret
resource "random_password" "db_master_password" {

  length  = 32
  special = false
}

resource "random_string" "secret_name_suffix" {
  length  = 6
  special = false
}

# Account-local key fine for development account
# tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "master_password" {
  # checkov:skip=CKV_AWS_149
  name = "${var.networking[0].application}-db-master-${random_string.secret_name_suffix.result}"

  tags = merge(
    local.tags,
    {
      Name = "${var.networking[0].application}-db-master-${random_string.secret_name_suffix.result}"
    },
  )
}

resource "aws_secretsmanager_secret_version" "master_password" {
  secret_id     = aws_secretsmanager_secret.master_password.id
  secret_string = random_password.db_master_password.result
}

resource "aws_db_parameter_group" "app" {
  name   = "sprinkler-pg"
  family = "postgres12"
  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1"
  }
}

# tfsec:ignore:aws-rds-specify-backup-retention
resource "aws_db_instance" "app" {
  # checkov:skip=CKV_AWS_118: "sprinkler does not need enhanced monitoring"
  # checkov:skip=CKV_AWS_129: "export to cloudwatch for logs is unneeded here"
  # checkov:skip=CKV_AWS_157: "multi-AZ deployment excessive for sprinkler"
  # checkov:skip=CKV_AWS_161: "IAM authentication excessive for sprinkler"
  # checkov:skip=CKV_AWS_226: "auto_upgrade_minor_version true by default"
  identifier                      = var.networking[0].application
  allocated_storage               = local.application_data.accounts[local.environment].rds_storage
  engine                          = "postgres"
  engine_version                  = local.application_data.accounts[local.environment].rds_postgresql_version
  instance_class                  = local.application_data.accounts[local.environment].rds_instance_class
  db_name                         = var.networking[0].application
  username                        = "dbmain"
  parameter_group_name            = aws_db_parameter_group.app.name
  password                        = random_password.db_master_password.result
  performance_insights_enabled    = true
  performance_insights_kms_key_id = data.aws_kms_key.rds.arn
  vpc_security_group_ids          = [aws_security_group.rds.id]
  db_subnet_group_name            = aws_db_subnet_group.app.id
  skip_final_snapshot             = true
  storage_encrypted               = true
  allow_major_version_upgrade     = false

  tags = merge(
    local.tags,
    {
      Name = var.networking[0].application
    }
  )
}

#------------------------------------------------------------------------------
# Logging
#------------------------------------------------------------------------------
#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "app" {
  #checkov:skip=CKV_AWS_158
  name              = var.networking[0].application
  retention_in_days = 90

  tags = merge(
    local.tags,
    {
      Name = var.networking[0].application
    },
  )
}

resource "aws_acm_certificate" "us_east_1_test" {
  domain_name       = "test.platforms-development.modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"
  provider          = aws.us-east-1

  tags = local.tags
}

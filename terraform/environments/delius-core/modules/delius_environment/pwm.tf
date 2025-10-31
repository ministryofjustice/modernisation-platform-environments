module "pwm" {
  source = "../helpers/delius_microservice"

  name                  = "pwd-manager"
  certificate_arn       = local.certificate_arn
  alb_security_group_id = aws_security_group.ancillary_alb_security_group.id
  env_name              = var.env_name
  container_port_config = [
    {
      containerPort = var.delius_microservice_configs.pwm.container_port
      protocol      = "tcp"
    }
  ]

  ecs_cluster_arn = module.ecs.ecs_cluster_arn

  db_ingress_security_groups = []

  cluster_security_group_id = aws_security_group.cluster.id

  bastion_sg_id = module.bastion_linux.bastion_security_group

  ecs_service_ingress_security_group_ids = []
  ecs_service_egress_security_group_ids = [
    {
      ip_protocol = "tcp"
      port        = 389
      cidr_ipv4   = var.account_config.shared_vpc_cidr
    },
    {
      ip_protocol = "tcp"
      port        = 25
      cidr_ipv4   = "10.180.104.0/22" # https://github.com/ministryofjustice/staff-infrastructure-network-services/blob/main/README.md#smtp-relay-service

    },
    {
      ip_protocol = "tcp"
      port        = 587
      cidr_ipv4   = "0.0.0.0/0"
    },
    {
      ip_protocol = "tcp"
      port        = 465
      cidr_ipv4   = "0.0.0.0/0"
    }
  ]

  tags                               = var.tags
  microservice_lb                    = aws_lb.delius_core_ancillary
  microservice_lb_https_listener_arn = aws_lb_listener.ancillary_https.arn


  alb_listener_rule_host_header = "pwm.${var.env_name}.${var.account_config.dns_suffix}"

  platform_vars = var.platform_vars

  container_image = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-password-management:${var.delius_microservice_configs.pwm.image_tag}"
  account_config  = var.account_config
  account_info    = var.account_info

  target_group_protocol_version = "HTTP1"

  alb_health_check = {
    path                 = "/"
    healthy_threshold    = 5
    interval             = 30
    protocol             = "HTTP"
    unhealthy_threshold  = 5
    matcher              = "200-499"
    timeout              = 10
    grace_period_seconds = 180
  }

  container_cpu                      = var.delius_microservice_configs.pwm.container_cpu
  container_memory                   = var.delius_microservice_configs.pwm.container_memory
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  # Define secrets here - override them by adding them to the container_secrets list eg var.delius_microservice_configs.pwm.container_secrets
  container_secrets_default = {
    "CONFIG_PASSWORD" : nonsensitive(aws_ssm_parameter.delius_core_pwm_config_password.arn),
    "LDAP_PASSWORD" : nonsensitive(aws_ssm_parameter.ldap_admin_password.arn),
    "SECURITY_KEY" : nonsensitive(aws_ssm_parameter.security_key.arn),
    "SES_JSON" : nonsensitive(aws_ssm_parameter.pwm_ses_smtp_user.arn)
  }

  container_secrets_env_specific = try(var.delius_microservice_configs.pwm.container_secrets_env_specific, {})

  container_vars_default = {
    "CONFIG_XML_BASE64" = base64encode(templatefile("${path.module}/templates/PwmConfiguration.xml.tpl", {
      ldap_host_url      = "ldap://${module.ldap_ecs.nlb_service_r53_record}:${var.ldap_config.port}"
      ldap_user          = nonsensitive(aws_ssm_parameter.ldap_principal.arn)
      pwm_url            = "https://pwm.${var.env_name}.${var.account_config.dns_suffix}"
      email_from_address = "no-reply@${aws_ses_domain_identity.pwm.domain}"
      email_smtp_address = "email-smtp.eu-west-2.amazonaws.com"
    })),
    "JAVA_OPTS" = "-Xmx${floor(var.delius_microservice_configs.pwm.container_memory * 0.75)}m -Xms${floor(var.delius_microservice_configs.pwm.container_memory * 0.25)}m"
  }
  container_vars_env_specific = try(var.delius_microservice_configs.pwm.container_vars_env_specific, {})

  ignore_changes_service_task_definition = true

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  log_error_pattern = "ERROR"

  log_error_threshold_config = {
    warning = {
      threshold = 10
      period    = 60
    }
    critical = {
      threshold = 20
      period    = 180
    }
  }
  ecs_monitoring_anomaly_detection_thresholds = {
    memory = 5
    cpu    = 20
  }

  sns_topic_arn           = aws_sns_topic.delius_core_alarms.arn
  frontend_lb_arn_suffix  = aws_lb.delius_core_ancillary.arn_suffix
  enable_platform_backups = var.enable_platform_backups
}

resource "aws_ssm_parameter" "security_key" {
  name  = "/${var.env_name}/pwm/security_key"
  type  = "SecureString"
  value = random_id.security_key.hex
}

resource "random_id" "security_key" {
  keepers = {
    image_tag = var.delius_microservice_configs.pwm.image_tag
  }
  byte_length = 32
}

#############
# SES
#############"

resource "aws_ses_domain_identity" "pwm" {
  domain = "pwm.${var.env_name}.${var.account_config.dns_suffix}"
}

resource "aws_ses_domain_identity_verification" "pwm" {
  domain = "pwm.${var.env_name}.${var.account_config.dns_suffix}"
}

resource "aws_route53_record" "pwm_ses_verification_record" {
  provider = aws.core-vpc
  zone_id  = var.account_config.route53_external_zone.zone_id
  name     = "_amazonses.${aws_ses_domain_identity.pwm.id}"
  type     = "TXT"
  ttl      = "600"
  records  = [aws_ses_domain_identity.pwm.verification_token]
}

resource "aws_ses_domain_identity_verification" "pwm_ses_verification" {
  domain     = aws_ses_domain_identity.pwm.id
  depends_on = [aws_route53_record.pwm_ses_verification_record]
}


resource "aws_ses_domain_dkim" "pwm" {
  domain = aws_ses_domain_identity.pwm.domain
}

resource "aws_route53_record" "pwm_amazonses_dkim_record" {
  provider = aws.core-vpc
  count    = 3
  zone_id  = var.account_config.route53_external_zone.zone_id
  name     = "${aws_ses_domain_dkim.pwm.dkim_tokens[count.index]}._domainkey.pwm.${var.env_name}.${var.account_info.application_name}"
  type     = "CNAME"
  ttl      = "600"
  records  = ["${aws_ses_domain_dkim.pwm.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_route53_record" "pwm_amazonses_dmarc_record" {
  provider = aws.core-vpc
  zone_id  = var.account_config.route53_external_zone.zone_id
  name     = "_dmarc.pwm.${var.env_name}.${var.account_config.dns_suffix}"
  type     = "TXT"
  ttl      = "600"
  records  = ["v=DMARC1; p=none;"]
}

#####################
# SES SMTP User
#####################

resource "aws_iam_user" "pwm_ses_smtp_user" {
  name = "${var.env_name}-pwm-smtp-user"
}

resource "aws_iam_access_key" "pwm_ses_smtp_user" {
  user = aws_iam_user.pwm_ses_smtp_user.name
}

resource "aws_iam_user_policy" "pwm_ses_smtp_user" {
  name = "${var.env_name}-pwm-ses-smtp-user-policy"
  user = aws_iam_user.pwm_ses_smtp_user.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ses:SendRawEmail",
          "ses:SendEmail"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_ssm_parameter" "pwm_ses_smtp_user" {
  name = "/${var.env_name}/pwm/ses_smtp"
  type = "SecureString"
  value = jsonencode({
    user              = aws_iam_user.pwm_ses_smtp_user.name,
    key               = aws_iam_access_key.pwm_ses_smtp_user.id,
    secret            = aws_iam_access_key.pwm_ses_smtp_user.secret
    ses_smtp_user     = aws_iam_access_key.pwm_ses_smtp_user.id
    ses_smtp_password = aws_iam_access_key.pwm_ses_smtp_user.ses_smtp_password_v4
  })
}

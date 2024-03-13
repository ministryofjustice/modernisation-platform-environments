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
  container_secrets = [
    {
      name      = "CONFIG_PASSWORD"
      valueFrom = aws_ssm_parameter.delius_core_pwm_config_password.arn
    },
    {
      name      = "LDAP_PASSWORD"
      valueFrom = aws_ssm_parameter.ldap_admin_password.arn
    },
    {
      name      = "SES_JSON"
      valueFrom = aws_ssm_parameter.pwm_ses_smtp_user.arn
    }
  ]

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

  container_image       = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-password-management:${var.delius_microservice_configs.pwm.image_tag}"
  account_config        = var.account_config
  health_check_path     = "/"
  health_check_interval = "15"
  account_info          = var.account_info

  target_group_protocol_version     = "HTTP1"
  health_check_grace_period_seconds = 10

  container_cpu                      = 1024
  container_memory                   = 2048
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  container_environment_vars = [
    {
      name = "CONFIG_XML_BASE64"
      value = base64encode(templatefile("${path.module}/templates/PwmConfiguration.xml.tpl", {
        ldap_host_url = "ldap://${module.ldap.nlb_dns_name}:${var.ldap_config.port}"
        ldap_user     = module.ldap.delius_core_ldap_principal_arn
        pwm_url       = "https://pwm.${var.env_name}.${var.account_config.dns_suffix}"
        # email_smtp_address = "smtp.${data.terraform_remote_state.vpc.outputs.private_zone_name}"
        #         email_smtp_address = "production-smtp-relay-70e032e2738d0a27.elb.eu-west-2.amazonaws.com"
        # email_from_address = "no-reply@${data.terraform_remote_state.vpc.outputs.public_zone_name}"
        # email_from_address = "noreply-ndelius-pwm-${var.env_name}@digital.justice.gov.uk"
        email_from_address = "no-reply@${aws_ses_domain_identity.pwm.domain}"
        email_smtp_address = "email-smtp.eu-west-2.amazonaws.com"
        rendered_email_challenge_token = templatefile("${path.module}/templates/email.html.tpl", {
          email_subject      = "Forgotten Password Verification"
          email_preview_text = "Forgotten Password Verification"
          email_header       = <<EOT
                                EmailItem default:
                                  To:@User:Email@
                                From:Forgotten Password <@DefaultEmailFromAddress@>
                                Subj:${email_subject}
                                Body:Thank you for requesting your account activation. To continue with your account activation, please copy and paste the following code onto the activation form:

                                %TOKEN%

                                If you did not request to create a new account, you do not need to take any action.
                                EOT
          email_body         = <<EOT
                                <b>If you do not wish to change your password at this time, you do not need to take any action.</b>
                                Html:Thank you for requesting a password reset.
                                <a style="word-wrap: break-word; color: #1D70B8;" href="https://pwm.${var.env_name}.${var.account_config.dns_suffix}/public/forgottenpassword/%TOKEN%" target="_blank">Click here to reset</a>.

                                If for some reason this link doesn't work, you can copy and paste the following code onto the password reset form:
                                <blockquote style="Margin: 0 0 20px 0; border-left: 10px solid #B1B4B6;padding: 15px 0 0.1px 15px; font-size: 19px; line-height: 25px;"><p style="Margin: 0 0 20px 0; font-size: 19px; line-height: 25px; color: #0B0C0C;">
                                  <span class="placeholder">%TOKEN%</span></p>
                                </blockquote>

                                <b>If you do not wish to change your password at this time, you do not need to take any action.</b>
                                EOT
        })
        rendered_email_pwd_changed = templatefile("${path.module}/templates/email.html.tpl", {
          email_subject      = "Password Changed"
          email_preview_text = "Password Changed"
          email_header       = <<EOT
                                EmailItem default:
                                  To:@User:Email@
                                From:Change Password Notice <@DefaultEmailFromAddress@>
                                Subj:Password Change Notification
                                Body:You have changed your password. If you did not initiate a password change please contact your help desk immediately.
                                EOT
          email_body         = <<EOT
                                <b>You have changed your password.</b> If you have changed your password, then no action is required. If you did not initiate a password change please contact your help desk.
                                EOT
        })

      }))
    },
    {
      name  = "SECURITY_KEY"
      value = "${base64encode(uuid())}"
    }
  ]

  ignore_changes_task_definition = true
  force_new_deployment           = false

  providers = {
    aws          = aws
    aws.core-vpc = aws.core-vpc
  }
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

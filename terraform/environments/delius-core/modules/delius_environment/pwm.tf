module "pwm" {
  source = "../helpers/delius_microservice"

  name                  = "password-manager"
  certificate_arn       = local.certificate_arn
  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
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
      name      = "SECURITY_KEY"
      valueFrom = "REPLACE"
    },
    {
      name      = "CONFIG_PASSWORD"
      valueFrom = aws_ssm_parameter.delius_core_pwm_config_password.arn
    },
    {
      name      = "LDAP_PASSWORD"
      valueFrom = aws_ssm_parameter.ldap_admin_password.arn
    }
  ]
  db_ingress_security_groups = []

  cluster_security_group_id = aws_security_group.cluster.id

  bastion_sg_id = module.bastion_linux.bastion_security_group

  tags                               = var.tags
  microservice_lb                    = aws_lb.delius_core_ancillary
  microservice_lb_https_listener_arn = aws_lb_listener.ancillary_https.arn


  alb_listener_rule_host_header = "pwm.${var.env_name}.${var.account_config.dns_suffix}"

  platform_vars = var.platform_vars

  container_image = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-password-manager:${var.delius_microservice_configs.pwm.image_tag}"
  account_config  = var.account_config
  #TODO check the health end-point
  health_check_path = "/pwm/actuator/health"
  account_info      = var.account_info

  container_environment_vars = [
    {
      name = "CONFIG_XML_BASE64"
      value = base64encode(templatefile("${path.module}/templates/PwmConfiguration.xml.tpl", {
        ldap_host_url = "ldap://${module.ldap.nlb_dns_name}:${var.ldap_config.port}"
        ldap_user     = module.ldap.delius_core_ldap_principal_arn
        pwm_url       = "pwm.${var.env_name}.${var.account_config.dns_suffix}"
        # email_smtp_address = "smtp.${data.terraform_remote_state.vpc.outputs.private_zone_name}"
        email_smtp_address = "REPLACE"
        # email_from_address = "no-reply@${data.terraform_remote_state.vpc.outputs.public_zone_name}"
        email_from_address = "REPLACE"
      }))
    }
  ]

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
  name     = "${aws_ses_domain_dkim.example.pwm[count.index]}._domainkey"
  type     = "CNAME"
  ttl      = "600"
  records  = ["${aws_ses_domain_dkim.pwm.dkim_tokens[count.index]}.dkim.amazonses.com"]
}
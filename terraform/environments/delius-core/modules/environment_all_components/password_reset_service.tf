locals {
  app_name = "password-reset"
}

module "password_reset_service" {
  source = "../components/delius_microservice"

  name                  = local.app_name
  certificate_arn       = local.certificate_arn
  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  env_name              = var.env_name
  container_port_config = [
    {
      containerPort = 8080
      protocol      = "tcp"
    }
  ]

  ecs_cluster_arn = module.ecs.ecs_cluster_arn
  container_secrets = [
    {
      name      = "SECURITY_KEY"
      valueFrom = "REPLACE"
      #   "/${var.environment_name}/${var.project_name}/pwm/pwm/security_key"
    },
    {
      name      = "CONFIG_PASSWORD"
      valueFrom = aws_ssm_parameter.delius_core_pwm_config_password.arn
      #value = "/${var.environment_name}/${var.project_name}/pwm/pwm/config_password"
    },
    {
      name      = "LDAP_PASSWORD"
      valueFrom = aws_ssm_parameter.ldap_admin_password.arn
      #value = "/${var.environment_name}/${var.project_name}/apacheds/apacheds/ldap_admin_password"
    }
  ]
  ingress_security_groups = []
  tags                    = var.tags
  microservice_lb_arn     = aws_lb.delius_core_frontend.arn
  platform_vars           = var.platform_vars
  container_image         = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-password-management-ecr-repo:${var.pwm_config.image_tag}"
  account_config          = var.account_config
  health_check_path       = "/gdpr/api/actuator/health"
  account_info            = var.account_info

  container_environment_vars = [
    {
      name = "CONFIG_XML_BASE64"
      value = base64encode(templatefile("${path.module}/templates/PwmConfiguration.xml.tpl", {
        region    = var.account_info["region"]
        ldap_url  = "ldap://${module.ldap.nlb_dns_name}:${local.ldap_port}"
        ldap_user = aws_ssm_parameter.delius_core_ldap_principal.arn
        user_base = "REPLACE"
        # site_url  = "https://${aws_route53_record.public_dns.fqdn}"
        site_url = "REPLACE"
        # email_smtp_address = "smtp.${data.terraform_remote_state.vpc.outputs.private_zone_name}"
        email_smtp_address = "REPLACE"
        # email_from_address = "no-reply@${data.terraform_remote_state.vpc.outputs.public_zone_name}"
        email_from_address = "REPLACE"
      }))
    }
  ]
}



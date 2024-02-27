module "password_reset_service" {
  source = "../components/delius_microservice"

  name                  = "password-reset"
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
      #   "/${var.environment_name}/${var.project_name}/pwm/pwm/security_key"
    },
    {
      name      = "CONFIG_PASSWORD"
      valueFrom = aws_ssm_parameter.delius_core_pwm_config_password.arn
      #value = "/${var.environment_name}/${var.project_name}/pwm/pwm/config_password"
    },
    {
      name      = "LDAP_PASSWORD"
      valueFrom = module.ldap.delius_core_ldap_bind_password_arn
      #value = "/${var.environment_name}/${var.project_name}/apacheds/apacheds/ldap_admin_password"
    }
  ]
  db_ingress_security_groups = []

  cluster_security_group_id = aws_security_group.cluster.id

  bastion_sg_id = module.bastion_linux.bastion_security_group

  tags                               = var.tags
  microservice_lb                    = aws_lb.delius_core_ancillary
  microservice_lb_https_listener_arn = aws_lb_listener.ancillary_https.arn

  #TODO - check the path based routing based on shared ALB or dedicated
  alb_listener_rule_paths = ["/password-reset"]
  platform_vars           = var.platform_vars
  container_image         = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-password-management-ecr-repo:${var.delius_microservice_configs.pwm.image_tag}"
  account_config          = var.account_config
  #TODO check the health end-point
  health_check_path = "/pwm/actuator/health"
  account_info      = var.account_info

  container_environment_vars = [
    {
      name = "CONFIG_XML_BASE64"
      value = base64encode(templatefile("${path.module}/templates/PwmConfiguration.xml.tpl", {
        region    = var.account_info["region"]
        ldap_url  = "ldap://${module.ldap.nlb_dns_name}:${var.ldap_config.port}"
        ldap_user = module.ldap.delius_core_ldap_principal_arn
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

  providers = {
    aws          = aws
    aws.core-vpc = aws.core-vpc
  }
}

#TODO move this to variable after merge

variable "pwm_config" {
  type = object({
    image_tag = string
  })
  default = {
    image_tag = "default_image_tag"
  }
}

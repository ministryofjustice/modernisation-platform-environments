module "pdf_creation" {
  source = "../helpers/delius_microservice"

  name                  = "pdf-creation"
  certificate_arn       = local.certificate_arn
  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  env_name              = var.env_name

  container_port_config = [
    {
      containerPort = var.delius_microservice_configs.pdf_creation.container_port
      protocol      = "tcp"
    }
  ]

  ecs_cluster_arn            = module.ecs.ecs_cluster_arn
  container_secrets          = []
  db_ingress_security_groups = []
  cluster_security_group_id  = aws_security_group.cluster.id

  bastion_sg_id                      = module.bastion_linux.bastion_security_group
  tags                               = var.tags
  microservice_lb                    = aws_lb.delius_core_frontend
  microservice_lb_https_listener_arn = aws_lb_listener.listener_https.arn

  alb_listener_rule_paths    = ["/pdf/creation", "/pdf/creation/*"]
  platform_vars              = var.platform_vars
  container_image            = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-pdf-creation-ecr-repo:${var.delius_microservice_configs.pdf_creation.image_tag}"
  account_config             = var.account_config
  health_check_path          = "/pdf/creation/"
  account_info               = var.account_info
  container_environment_vars = []

  providers = {
    aws          = aws
    aws.core-vpc = aws.core-vpc
  }

  log_error_pattern      = "ERROR"
  sns_topic_arn          = aws_sns_topic.delius_core_alarms.arn
  frontend_lb_arn_suffix = aws_lb.delius_core_frontend.arn_suffix
}


resource "aws_ssm_parameter" "pdfcreation_secret" {
  name  = "/${var.env_name}/delius/newtech/web/params_secret_key"
  type  = "SecureString"
  value = "DEFAULT"
  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_ssm_parameter" "pdfcreation_secret" {
  name = aws_ssm_parameter.pdfcreation_secret.name
}

module "weblogic_eis" {
  source = "../helpers/delius_microservice"

  providers = {
    aws                       = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  name              = "weblogic-eis"
  create_service    = "false"
  env_name          = var.env_name
  account_config    = var.account_config
  account_info      = var.account_info
  capacity_provider = aws_ecs_capacity_provider.weblogic_eis.name

  force_new_deployment = false

  ecs_cluster_arn  = module.ecs.ecs_cluster_arn

  # container_secrets_default = merge({
  #   for name in local.weblogic_secrets : name => module.weblogic_ssm.arn_map[name]
  #   }, {
  #   "JDBC_PASSWORD"         = "${module.oracle_db_shared.database_application_passwords_secret_arn}:delius_pool::",
  #   "USERMANAGEMENT_SECRET" = data.aws_ssm_parameter.usermanagement_secret.arn
  #   }
  # )

  cluster_security_group_id = aws_security_group.cluster.id

  alb_security_group_id      = aws_security_group.delius_frontend_alb_security_group.id
  alb_listener_rule_paths    = ["/eis"]
  alb_listener_rule_priority = 40
  alb_health_check = {
    path                 = "/NDelius-war/delius/javax.faces.resource/health/healthcheck.json"
    healthy_threshold    = 5
    interval             = 30
    protocol             = "HTTP"
    unhealthy_threshold  = 5
    matcher              = "200"
    timeout              = 10
    grace_period_seconds = 300
  }

  certificate_arn = aws_acm_certificate.external.arn

  db_ingress_security_groups = []

  microservice_lb                    = aws_lb.delius_core_frontend
  microservice_lb_https_listener_arn = aws_lb_listener.listener_https.arn

  bastion_sg_id = module.bastion_linux.bastion_security_group

  ecs_service_ingress_security_group_ids = []
  ecs_service_egress_security_group_ids = [
    {
      ip_protocol = "tcp"
      port        = 389
      cidr_ipv4   = var.account_config.shared_vpc_cidr
    },
    {
      ip_protocol = "udp"
      port        = 389
      cidr_ipv4   = var.account_config.shared_vpc_cidr
    },
    {
      ip_protocol = "tcp"
      port        = 1521
      cidr_ipv4   = var.account_config.shared_vpc_cidr
    }
  ]

  log_error_pattern       = ""
  sns_topic_arn           = aws_sns_topic.delius_core_alarms.arn
  frontend_lb_arn_suffix  = aws_lb.delius_core_frontend.arn_suffix
  enable_platform_backups = var.enable_platform_backups

  platform_vars = var.platform_vars
  tags          = var.tags
}


#######################
# Weblogic EIS Params #
#######################

resource "aws_ssm_parameter" "weblogic_eis_google_analytics_id" {
  name  = "/${var.env_name}/delius/monitoring/analytics/google_id"
  type  = "String"
  value = "DEFAULT"
  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_ssm_parameter" "weblogic_eis_google_analytics_id" {
  name = aws_ssm_parameter.weblogic_eis_google_analytics_id.name
}

resource "aws_ssm_parameter" "usermanagement_secret" {
  name  = "/${var.env_name}/delius/umt/umt/delius_secret"
  type  = "SecureString"
  value = "DEFAULT"
  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_ssm_parameter" "usermanagement_secret" {
  name = aws_ssm_parameter.usermanagement_secret.name
}

resource "aws_launch_template" "weblogic_eis" {
  name_prefix   = "weblogic-eis-${var.env_name}-ecs-"
  image_id      = data.aws_ami.ecs_ami.id
  instance_type = var.delius_microservice_configs.weblogic_eis.ec2_instance_type

  user_data = base64encode(templatefile("${path.module}/templates/ecs-host-userdata.tpl", { ecs_cluster_name = module.ecs.ecs_cluster_name }))

  network_interfaces {
    associate_public_ip_address = false
    security_groups = [
      aws_security_group.ecs_host_sg.id
    ]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.weblogic.name
  }
}

resource "aws_autoscaling_group" "weblogic_eis" {
  name = "weblogic-eis-${var.env_name}-ecs-asg"

  max_size              = 1
  min_size              = 1
  protect_from_scale_in = true

  vpc_zone_identifier = var.account_config.private_subnet_ids

  instance_refresh {
    strategy = "Rolling"
  }

  launch_template {
    id      = aws_launch_template.weblogic_eis.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "weblogic-eis-${var.env_name}-ecs-asg"
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "weblogic_eis" {
  name = "weblogic-eis-${var.env_name}-ec2-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.weblogic_eis.arn

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100
    }

    managed_termination_protection = "ENABLED"
  }
}

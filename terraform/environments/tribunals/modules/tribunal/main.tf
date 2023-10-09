locals {
  app = var.app_name
  app_url = var.app_url
  sql_migration_path = var.sql_migration_path
  app_db_name = var.app_db_name
  app_db_login_name = var.app_db_login_name
  app_source_db_name = var.app_source_db_name
  app_rds_url               = "${var.app_rds_url}"      
  app_rds_user              = "${app_rds_user}"
  app_rds_port              = var.app_rds_port
  app_rds_password          = "${var.app_rds_password}"
  app_source_db_url         = "${var.app_source_db_url}"
  app_source_db_user        = "${var.app_source_db_user}"
  app_source_db_password    = "${var.app_source_db_password}"
  app_user_data = base64encode(templatefile("user_data.sh", {
    cluster_name = "${local.app}_app_cluster"
  }))
  app_task_definition = templatefile("task_definition.json", {
    app_name            = "${local.app}"
    #ecr_url             = "mcr.microsoft.com/dotnet/framework/aspnet:4.8"
    #docker_image_tag    = "latest" 
    #sentry_env          = local.environment
    awslogs-group       = "${local.app}-ecs-log-group"
    supportEmail        = "${var.application_data.support_email}"
    supportTeam         = "${var.application_data.support_team}"
    CurServer           = "${var.application_data.curserver}"

  })
  app_ec2_ingress_rules = {   
    "cluster_ec2_lb_ingress_2" = {
      description     = "Cluster EC2 ingress rule 2"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }
  app_ec2_egress_rules = {
    "cluster_ec2_lb_egress" = {
      description     = "Cluster EC2 loadbalancer egress rule"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }
}

######################## DMS #############################################

module "app_dms" {
  source                      = "../dms"
  replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
  replication_task_id         = "${local.app}-migration-task"
  #target_db_instance          = 0
  target_endpoint_id          = "${local.app}-target"
  target_database_name        = local.app_db_name
  target_server_name          = local.app_rds_url
  target_username             = local.app_rds_user
  target_password             = local.app_rds_password
  source_endpoint_id          = "${local.app}-source"
  source_database_name        = local.app_source_db_name
  source_server_name          = local.app_source_db_url
  source_username             = local.app_source_db_user
  source_password             = local.app_source_db_password
 
}

############################################################################

resource "random_password" "app_new_password" {
  length  = 16
  special = false 
}

resource "null_resource" "app_setup_db" {
 
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "ifconfig -a; chmod +x ./setup-mssql.sh; ./setup-mssql.sh"

    environment = {
      DB_URL = local.app_rds_url   
      USER_NAME = local.app_rds_user
      PASSWORD = local.app_rds_password
      NEW_DB_NAME = local.app_db_name
      NEW_USER_NAME = local.app_db_login_name
      NEW_PASSWORD = random_password.app_new_password.result
      APP_FOLDER = local.sql_migration_path
    }
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

 resource "aws_secretsmanager_secret" "app_db_credentials" {
  name = "${local.app}-db-credentials"
}

resource "aws_secretsmanager_secret_version" "app_db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.app_db_credentials.id
  secret_string = <<EOF
{
  "username": "${local.app_db_login_name}",
  "password": "${random_password.app_new_password.result}",  
  "host": "${local.app_rds_url}",  
  "database_name": "${local.app_db_name}"
}
EOF
}

####################### DNS #########################################

// ACM Public Certificate
resource "aws_acm_certificate" "app_external" {
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = ["${local.app_url}.${var.networking[0].business-unit}-${var.environment}.modernisation-platform.service.justice.gov.uk"]
  tags = {
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "app_external" {
  certificate_arn         = aws_acm_certificate.app_external.arn
  validation_record_fqdns = var.validation_record_fqdns
}

####################### LOAD BALANCER #########################################
resource "aws_security_group" "app_lb_sc" {
  name        = "${local.app} load balancer security group"
  description = "control access to the ${local.app} load balancer"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "allow access on HTTPS for the MOJ VPN"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.application_data.var.moj_ip]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }

  egress {
    description = "allow all outbound traffic for port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow all outbound traffic for port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
}

resource "aws_lb" "app_lb" {
  name                       = "${local.app}-load-balancer"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.app_lb_sc.id]
  subnets                    = data.aws_subnets.shared-public.ids
  enable_deletion_protection = false
  internal                   = false
  depends_on                 = [aws_security_group.app_lb_sc]
}

resource "aws_lb_target_group" "app_target_group" {
  name                 = "${local.app}-target-group"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    healthy_threshold   = "2"
    interval            = "120"
    protocol            = "HTTP"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "10"
  }

}

resource "aws_lb_listener" "app_lb" {
  depends_on = [
    aws_acm_certificate.app_external
  ]
  certificate_arn   = aws_acm_certificate.app_external.arn
  #certificate_arn   = local.is-production ? aws_acm_certificate.app_external_prod[0].arn : aws_acm_certificate.app_external.arn
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}

####################### ECS #########################################

module "app-ecs" {

  source = "../ecs"

  subnet_set_name           = var.subnet_set_name
  vpc_all                   = var.vpc_all
  app_name                  = local.app
  container_instance_type   = "windows"
  ami_image_id              = var.application_data.ami_image_id
  instance_type             = var.application_data.instance_type
  user_data                 = local.app_user_data
  key_name                  = ""
  task_definition           = local.app_task_definition
  ec2_desired_capacity      = var.application_data.ec2_desired_capacity
  ec2_max_size              = var.application_data.ec2_max_size
  ec2_min_size              = var.application_data.ec2_min_size
  task_definition_volume    = var.application_data.task_definition_volume
  network_mode              = var.application_data.network_mode
  server_port               = var.application_data.server_port_1
  app_count                 = var.application_data.app_count
  ec2_ingress_rules         = local.app_ec2_ingress_rules
  ec2_egress_rules          = local.app_ec2_egress_rules
  lb_tg_arn                 = aws_lb_target_group.app_target_group.arn
  tags_common               = var.tags
  appscaling_min_capacity   = var.application_data.appscaling_min_capacity
  appscaling_max_capacity   = var.application_data.appscaling_max_capacity
  ec2_scaling_cpu_threshold = var.application_data.ec2_scaling_cpu_threshold
  ec2_scaling_mem_threshold = var.application_data.ec2_scaling_mem_threshold
  ecs_scaling_cpu_threshold = var.application_data.ecs_scaling_cpu_threshold
  ecs_scaling_mem_threshold = var.application_data.ecs_scaling_mem_threshold  
  environment               = var.environment
  //fsx_vpc_id                = data.aws_vpc.shared.id
  lb_listener               = aws_lb_listener.app_lb
}

resource "aws_ecr_repository" "app-ecr-repo" {
  name         = "${local.app}-ecr-repo"
  force_delete = true
}
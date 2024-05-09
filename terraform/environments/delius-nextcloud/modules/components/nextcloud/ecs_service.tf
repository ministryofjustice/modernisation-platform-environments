module "nextcloud_service" {
  source = "../../../../delius-core/modules/helpers/delius_microservice"

  account_config            = var.account_config
  account_info              = var.account_info
  alb_security_group_id     = aws_security_group.nextcloud_alb_sg.id
  bastion_sg_id             = var.bastion_sg_id
  certificate_arn           = aws_acm_certificate.nextcloud_external.arn
  cluster_security_group_id = aws_security_group.cluster.id

  target_group_protocol_version = "HTTP1"

  container_image = "nextcloud:latest"
  container_port_config = [
    {
      containerPort = "80"
      protocol      = "tcp"
    }
  ]

  desired_count                      = 3
  deployment_maximum_percent         = "200"
  deployment_minimum_healthy_percent = "100"

  ecs_service_egress_security_group_ids = [
    for efs in module.nextcloud_efs : {
      ip_protocol                  = "tcp"
      port                         = 2049
      referenced_security_group_id = efs.sg_id
    }
  ]

  efs_volumes = [
    for efs in module.nextcloud_efs : {
      host_path = null
      name      = efs.name
      efs_volume_configuration = [{
        file_system_id          = efs.fs_id
        root_directory          = "/"
        transit_encryption      = "ENABLED"
        transit_encryption_port = null
        authorization_config = [{
          access_point_id = efs.access_point_id
          iam             = "DISABLED"
        }]
      }]
    }
  ]
  mount_points = [for efs in module.nextcloud_efs : {
    sourceVolume  = efs.name
    containerPath = "/var/www/${efs.name}"
    readOnly      = false
  }]

  ecs_cluster_arn   = module.ecs.ecs_cluster_arn
  env_name          = var.env_name
  health_check_path = "/status.php"
  #health_check_path                  = "/"
  alb_listener_rule_paths            = ["/"]
  microservice_lb_https_listener_arn = aws_alb_listener.nextcloud_https.arn
  microservice_lb                    = aws_alb.nextcloud
  name                               = "nextcloud"

  create_rds               = true
  rds_engine               = "mariadb"
  rds_engine_version       = "10.4.30"
  rds_instance_class       = "db.t3.small"
  rds_allocated_storage    = 500
  rds_username             = "misnextcloud"
  rds_port                 = 3306
  rds_parameter_group_name = "default.mariadb10.4."
  rds_license_model        = "general-public-license"
  snapshot_identifier      = "nextcloud-migration-1251-shared"

  rds_allow_major_version_upgrade = true
  rds_apply_immediately           = true

  create_elasticache               = true
  elasticache_engine               = "redis"
  elasticache_engine_version       = "6.x"
  elasticache_node_type            = "cache.t3.small"
  elasticache_port                 = 6379
  elasticache_parameter_group_name = "default.redis6.x"
  elasticache_subnet_group_name    = "nextcloud-elasticache-subnet-group"

  db_ingress_security_groups = [aws_security_group.cluster.id]

  rds_endpoint_environment_variable         = "MYSQL_HOST"
  elasticache_endpoint_environment_variable = "REDIS_HOST"

  container_vars_default = {
    MYSQL_DATABASE            = "nextcloud"
    MYSQL_USER                = "dbadmin"
    MYSQL_PASSWORD            = "password"
    REDIS_PORT                = "6379"
    REDIS_PASSWORD            = "password"
    NEXTCLOUD_ADMIN_USER      = "admin"
    NEXTCLOUD_TRUSTED_DOMAINS = aws_route53_record.nextcloud_external.fqdn
  }
  container_vars_env_specific = {}

  container_secrets_env_specific = {}

  container_secrets_default = {
    NEXTCLOUD_ADMIN_PASSWORD = aws_secretsmanager_secret.nextcloud_admin_password.arn
  }

  log_error_pattern      = "FATAL"
  sns_topic_arn          = aws_sns_topic.nextcloud_alarms.arn
  frontend_lb_arn_suffix = aws_alb.nextcloud.arn_suffix

  platform_vars = var.platform_vars
  tags          = var.tags

  providers = {
    aws.core-vpc = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

}

resource "aws_secretsmanager_secret" "nextcloud_admin_password" {
  name = "nextcloud-admin-password"
}

resource "aws_secretsmanager_secret_version" "nextcloud_admin_password" {
  secret_id     = aws_secretsmanager_secret.nextcloud_admin_password.id
  secret_string = random_password.nextcloud_admin_password.result
}

resource "random_password" "nextcloud_admin_password" {
  length  = 32
  special = true
}

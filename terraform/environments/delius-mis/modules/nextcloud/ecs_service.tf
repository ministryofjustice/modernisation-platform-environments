module "nextcloud_service" {
  source = "../../../delius-core/modules/helpers/delius_microservice"

  account_config            = var.account_config
  account_info              = var.account_info
  alb_security_group_id     = aws_security_group.nextcloud_alb_sg.id
  bastion_sg_id             = var.bastion_sg_id
  certificate_arn           = aws_acm_certificate.nextcloud_external.arn
  cluster_security_group_id = aws_security_group.cluster.id

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


  efs_volumes = [
    {
      host_path = null
      name      = "nextcloud"
      efs_volume_configuration = [{
        file_system_id          = module.nextcloud_efs.fs_id
        root_directory          = "/"
        transit_encryption      = "ENABLED"
        transit_encryption_port = 2049
        authorization_config = [{
          access_point_id = module.nextcloud_efs.access_point_id
          iam             = "DISABLED"
        }]
      }]
    }
  ]
  mount_points = [{
    sourceVolume  = "nextcloud"
    containerPath = "/var/www/"
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
  rds_engine_version       = "10.6"
  rds_instance_class       = "db.t3.small"
  rds_allocated_storage    = 500
  rds_username             = "misnextcloud"
  rds_port                 = 3306
  rds_parameter_group_name = "default.mariadb10.6"
  rds_license_model        = "general-public-license"
  snapshot_identifier      = "nextcloud-correct"

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

  container_environment_vars = [
    {
      name  = "MYSQL_DATABASE"
      value = "nextcloud"
    },
    {
      name  = "MYSQL_USER"
      value = "dbadmin"
    },
    {
      name  = "MYSQL_PASSWORD"
      value = "password"
    },
    {
      name  = "REDIS_PORT"
      value = "6379"
    },
    {
      name  = "REDIS_PASSWORD"
      value = "password"
    },
    {
      name  = "NEXTCLOUD_ADMIN_USER"
      value = "admin"
    },
    {
      name  = "NEXTCLOUD_TRUSTED_DOMAINS"
      value = aws_route53_record.nextcloud_external.fqdn
    }
  ]

  container_secrets = [
    {
      name      = "NEXTCLOUD_ADMIN_PASSWORD"
      valueFrom = aws_secretsmanager_secret.nextcloud_admin_password.arn
    }
  ]

  platform_vars = var.platform_vars
  tags          = var.tags

  providers = {
    aws          = aws
    aws.core-vpc = aws.core-vpc
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

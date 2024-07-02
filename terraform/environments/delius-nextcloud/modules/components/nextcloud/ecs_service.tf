module "nextcloud_service" {
  source = "../../../../delius-core/modules/helpers/delius_microservice"

  account_config            = var.account_config
  account_info              = var.account_info
  alb_security_group_id     = aws_security_group.nextcloud_alb_sg.id
  bastion_sg_id             = var.bastion_sg_id
  certificate_arn           = aws_acm_certificate.nextcloud_external.arn
  cluster_security_group_id = aws_security_group.cluster.id

  target_group_protocol_version = "HTTP1"

  container_image = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-nextcloud:latest"
  container_port_config = [
    {
      containerPort = "80"
      protocol      = "tcp"
    }
  ]

  desired_count                      = 1
  deployment_maximum_percent         = "100"
  deployment_minimum_healthy_percent = "0"

  ecs_service_egress_security_group_ids = concat([
    for efs in module.nextcloud_efs : {
      ip_protocol                  = "tcp"
      port                         = 2049
      referenced_security_group_id = efs.sg_id
    }], [
    {
      ip_protocol = "tcp"
      port        = 389
      cidr_ipv4   = var.account_info.cp_cidr
    }
  ])

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
  mount_points = [for k, v in module.nextcloud_efs : {
    sourceVolume  = v.name
    containerPath = "/var/www/${replace(k, "data", "html/data")}"
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


  container_cpu    = 2048
  container_memory = 4096

  extra_task_role_policies = {
    "S3_BUCKET_CONFIG"   = data.aws_iam_policy_document.s3_bucket_config
    "access_ldap_secret" = data.aws_iam_policy_document.access_ldap_secret
  }

  create_rds               = true
  rds_engine               = "mariadb"
  rds_engine_version       = "10.5"
  rds_instance_class       = "db.t3.small"
  rds_allocated_storage    = 500
  rds_username             = "misnextcloud"
  rds_port                 = 3306
  rds_parameter_group_name = "default.mariadb10.5"
  rds_license_model        = "general-public-license"
  snapshot_identifier      = "nextcloud-rds-19062024"

  rds_allow_major_version_upgrade = true
  rds_apply_immediately           = true

  create_elasticache               = true
  elasticache_engine               = "redis"
  elasticache_engine_version       = "6.x"
  elasticache_node_type            = "cache.t3.small"
  elasticache_port                 = 6379
  elasticache_parameter_group_name = "default.redis6.x"

  db_ingress_security_groups = []

  rds_endpoint_environment_variable         = "MYSQL_HOST"
  rds_password_secret_variable              = "MYSQL_PASSWORD"
  rds_user_secret_variable                  = "MYSQL_USER"
  elasticache_endpoint_environment_variable = "REDIS_HOST"

  container_vars_default = {
    MYSQL_DATABASE            = "nextcloud"
    REDIS_HOST_PORT           = "6379"
    NEXTCLOUD_ADMIN_USER      = "admin"
    NEXTCLOUD_TRUSTED_DOMAINS = aws_route53_record.nextcloud_external.fqdn
    S3_BUCKET_CONFIG          = module.s3_bucket_config.bucket.id
    LDAP_PASSWORD_SECRET_ARN  = "arn:aws:secretsmanager:eu-west-2:${var.platform_vars.environment_management.account_ids[join("-", ["delius-core", var.account_info.mp_environment])]}:secret:ldap-admin-password-${var.env_name}"
  }

  container_vars_env_specific = {}

  container_secrets_env_specific = {}



  container_secrets_default = {
    NEXTCLOUD_ADMIN_PASSWORD = aws_secretsmanager_secret.nextcloud_admin_password.arn
  }

  log_error_pattern      = "ERROR"
  sns_topic_arn          = aws_sns_topic.nextcloud_alarms.arn
  frontend_lb_arn_suffix = aws_alb.nextcloud.arn_suffix

  platform_vars = var.platform_vars
  tags          = var.tags

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  ignore_changes_service_task_definition = false

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


data "aws_iam_policy_document" "s3_bucket_config" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [module.s3_bucket_config.bucket.arn]
  }
}

data "aws_iam_policy_document" "access_ldap_secret" {
  statement {
    sid = "AccessToSecretsManager"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:secretsmanager:eu-west-2:${var.platform_vars.environment_management.account_ids[join("-", ["delius-core", var.account_info.mp_environment])]}:secret:ldap-admin-password*"
    ]
  }
  statement {
    sid = "kmsAccess"
    actions = [
      "kms:Decrypt"
    ]
    effect = "Allow"
    resources = [
      var.account_config.kms_keys.general_shared
    ]
  }
}

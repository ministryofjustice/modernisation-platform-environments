module "nextcloud_service" {
  source = "../delius-core/modules/components/delius_microservice"

  account_config = {
    shared_vpc_cidr               = data.aws_vpc.shared.cidr_block
    private_subnet_ids            = data.aws_subnets.shared-private.ids
    public_subnet_ids             = data.aws_subnets.shared-public.ids
    ordered_private_subnet_ids    = local.ordered_subnet_ids
    ordered_subnets               = [local.ordered_subnet_ids]
    data_subnet_ids               = data.aws_subnets.shared-data.ids
    data_subnet_a_id              = data.aws_subnet.data_subnets_a.id
    route53_inner_zone_info       = data.aws_route53_zone.inner
    route53_network_services_zone = data.aws_route53_zone.network-services
    route53_external_zone         = data.aws_route53_zone.external
    shared_vpc_id                 = data.aws_vpc.shared.id
    kms_keys = {
      ebs_shared     = data.aws_kms_key.ebs_shared.arn
      general_shared = data.aws_kms_key.general_shared.arn
      rds_shared     = data.aws_kms_key.rds_shared.arn
    }
    dns_suffix = "${local.application_name}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  }
  account_info = {
    business_unit    = var.networking[0].business-unit
    region           = "eu-west-2"
    vpc_id           = data.aws_vpc.shared.id
    application_name = local.application_name
    mp_environment   = local.environment
    id               = data.aws_caller_identity.current.account_id
    cp_cidr          = "172.20.0.0/16"
  }
  alb_security_group_id      = aws_security_group.nextcloud_alb_sg.id
  bastion_sg_id              = module.bastion_linux.bastion_security_group
  certificate_arn            = aws_acm_certificate.nextcloud_external.arn
  cluster_security_group_id  = aws_security_group.cluster.id
  container_environment_vars = []
  container_image            = "nextcloud:latest"
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

  container_secrets                  = []
  ecs_cluster_arn                    = module.ecs.ecs_cluster_arn
  env_name                           = local.environment
  health_check_path                  = "/status.php"
  alb_listener_rule_paths            = ["/"]
  microservice_lb_https_listener_arn = aws_alb_listener.nextcloud_https.arn
  microservice_lb_arn                = aws_alb.nextcloud.arn
  name                               = "nextcloud"

  create_rds                       = true
  rds_engine                       = "mariadb"
  rds_engine_version               = "10.6"
  rds_instance_class               = "db.t3.small"
  rds_allocated_storage            = 20
  rds_username                     = "dbadmin"
  rds_port                         = 3306
  rds_parameter_group_name         = "default.mariadb10.6"
  create_elasticache               = true
  elasticache_engine               = "redis"
  elasticache_engine_version       = "6.x"
  elasticache_node_type            = "cache.t3.small"
  elasticache_port                 = 6379
  elasticache_parameter_group_name = "default.redis6.x"
  elasticache_subnet_group_name    = "nextcloud-elasticache-subnet-group"

  db_ingress_security_groups = [aws_security_group.cluster.id]


  platform_vars = {
    environment_management = local.environment_management
  }
  tags = local.tags

  providers = {
    aws          = aws
    aws.core-vpc = aws.core-vpc
  }
}

resource "aws_security_group" "nextcloud_alb_sg" {
  name        = "delius-mis-nextcloud-alb-sg"
  description = "Security group for the nextcloud alb"
  vpc_id      = data.aws_vpc.shared.id
  tags        = local.tags
}

resource "aws_vpc_security_group_egress_rule" "alb_to_nextcloud_ecs_service" {
  security_group_id            = aws_security_group.nextcloud_alb_sg.id
  description                  = "Allow traffic from the nextcloud alb to the nextcloud ecs service"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "TCP"
  referenced_security_group_id = module.nextcloud_service.service_security_group_id
}

resource "aws_alb" "nextcloud" {
  name               = "nextcloud"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.nextcloud_alb_sg.id]
  subnets            = data.aws_subnets.shared-public.ids
  tags               = local.tags
}

resource "aws_alb_listener" "nextcloud_https" {
  load_balancer_arn = aws_alb.nextcloud.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.nextcloud_external.arn

  default_action {
    type             = "forward"
    target_group_arn = module.nextcloud_service.target_group_arn
  }
}

module "nextcloud_efs" {
  source = "../delius-core/modules/efs"

  name           = "nextcloud"
  env_name       = local.environment
  creation_token = "${local.environment}-nextcloud-efs"

  kms_key_arn                     = data.aws_kms_key.general_shared.arn
  throughput_mode                 = "bursting"
  provisioned_throughput_in_mibps = null
  tags                            = local.tags

  vpc_id     = data.aws_vpc.shared.id
  subnet_ids = local.ordered_subnet_ids
  vpc_cidr   = data.aws_vpc.shared.cidr_block
}

resource "aws_security_group_rule" "efs_ingress_nextcloud" {
  type                     = "egress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = module.nextcloud_efs.sg_id
  security_group_id        = module.nextcloud_service.service_security_group_id
}

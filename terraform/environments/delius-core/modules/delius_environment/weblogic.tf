module "weblogic" {
  source = "../helpers/delius_microservice"

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  name              = "weblogic"
  container_image   = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-weblogic:${var.delius_microservice_configs.weblogic.image_tag}"
  env_name          = var.env_name
  account_config    = var.account_config
  account_info      = var.account_info
  capacity_provider = aws_ecs_capacity_provider.weblogic.name

  force_new_deployment = true

  desired_count = 1

  pin_task_definition_revision           = try(var.delius_microservice_configs.weblogic.task_definition_revision, 0)
  ignore_changes_service_task_definition = false

  ecs_cluster_arn  = module.ecs.ecs_cluster_arn
  container_memory = var.delius_microservice_configs.weblogic.container_memory
  container_cpu    = var.delius_microservice_configs.weblogic.container_cpu

  container_vars_default = {
    for key, name in var.delius_microservice_configs.weblogic_params : key => data.aws_ssm_parameter.weblogic_ssm[key].value
  }
  container_vars_env_specific = try(var.delius_microservice_configs.weblogic.container_vars_env_specific, {})

  container_secrets_default = merge({
    for name in local.weblogic_secrets : name => module.weblogic_ssm.arn_map[name]
    }, {
    "JDBC_PASSWORD" = "${module.oracle_db_shared.database_application_passwords_secret_arn}:delius_pool::"
    }
  )
  container_secrets_env_specific = try(var.delius_microservice_configs.weblogic.container_secrets_env_specific, {})

  container_port_config = [
    {
      containerPort = var.delius_microservice_configs.weblogic.container_port
      protocol      = "tcp"
    }
  ]

  cluster_security_group_id = aws_security_group.cluster.id

  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  alb_health_check = {
    path                 = "/NDelius-war/delius/JSP/healthcheck.jsp?ping"
    healthy_threshold    = 5
    interval             = 30
    protocol             = "HTTP"
    unhealthy_threshold  = 5
    matcher              = "200-499"
    timeout              = 5
    grace_period_seconds = 300
  }

  certificate_arn               = aws_acm_certificate.external.arn
  target_group_protocol_version = "HTTP1"

  db_ingress_security_groups = []

  microservice_lb = aws_lb.delius_core_frontend

  bastion_sg_id = module.bastion_linux.bastion_security_group

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

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

  log_error_pattern      = "FATAL"
  sns_topic_arn          = aws_sns_topic.delius_core_alarms.arn
  frontend_lb_arn_suffix = aws_lb.delius_core_frontend.arn_suffix

  platform_vars = var.platform_vars
  tags          = var.tags
}

# Search for ami id
data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  # Amazon Linux 2 optimised ECS instance
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*"]
  }

  # correct arch
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  # Owned by Amazon
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "weblogic" {
  name_prefix   = "weblogic-${var.env_name}-ecs-"
  image_id      = data.aws_ami.ecs_ami.id
  instance_type = var.delius_microservice_configs.weblogic.ec2_instance_type

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

# ECS IAM
resource "aws_iam_role" "weblogic_host" {
  name               = "weblogic-${var.env_name}-ecshost-private-iam"
  assume_role_policy = templatefile("${path.module}/templates/ecs-host-assumerole-policy.tpl", {})
}

resource "aws_iam_role_policy" "weblogic" {
  name = "weblogic-${var.env_name}-ecshost-private-iam"
  role = aws_iam_role.weblogic_host.name

  policy = templatefile("${path.module}/templates/ecs-host-role-policy.tpl", {})
}

data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  name = "AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  policy_arn = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
  role       = aws_iam_role.weblogic_host.name
}

resource "aws_iam_instance_profile" "weblogic" {
  name = "weblogic-${var.env_name}-ecscluster-private-iam"
  role = aws_iam_role.weblogic_host.name
}

resource "aws_security_group" "ecs_host_sg" {
  name        = "weblogic-${var.env_name}-ecscluster-private-sg"
  description = "Shared ECS Cluster Hosts Security Group"
  vpc_id      = var.account_info.vpc_id

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "weblogic-${var.env_name}-ecscluster-private-sg" })
}

resource "aws_autoscaling_group" "weblogic" {
  name = "weblogic-${var.env_name}-ecs-asg"

  max_size              = 2
  min_size              = 1
  desired_capacity      = 1
  protect_from_scale_in = true

  vpc_zone_identifier = var.account_config.private_subnet_ids

  launch_template {
    id      = aws_launch_template.weblogic.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "weblogic-${var.env_name}-ecs-asg"
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "weblogic" {
  name = "weblogic-${var.env_name}-ec2-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.weblogic.arn

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100
    }

    managed_termination_protection = "ENABLED"
  }
}
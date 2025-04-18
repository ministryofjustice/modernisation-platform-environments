#### This file can be used to store locals specific to the member account ####

locals {
  env_account_id       = local.environment_management.account_ids[terraform.workspace]
  application_test_url = "https://mlra.laa-development.modernisation-platform.service.justice.gov.uk/mlra/"

  # ECS local variables for ecs.tf
  ec2_ingress_rules = {
    "cluster_ec2_lb_ingress_3" = {
      description     = "Cluster EC2 ingress rule 3"
      from_port       = 32768
      to_port         = 61000
      protocol        = "tcp"
      cidr_blocks     = []
      security_groups = [module.alb.security_group.id]
    }
  }
  ec2_egress_rules = {
    "cluster_ec2_lb_egress" = {
      description     = "Cluster EC2 loadbalancer egress rule"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }

  user_data = base64encode(templatefile("user_data.sh", {
    app_name = local.application_name
  }))

  maatdb_password_secret_name = "APP_MAATDB_DBPASSWORD_MLA1"
  gtm_id_secret_name          = "APP_MLRA_GOOGLE_TAG_MANAGER_ID"
  task_definition = templatefile("task_definition.json", {
    app_name              = local.application_name
    ecr_url               = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/mlra-ecr-repo"
    docker_image_tag      = local.application_data.accounts[local.environment].docker_image_tag
    region                = local.application_data.accounts[local.environment].region
    maat_api_end_point    = local.application_data.accounts[local.environment].maat_api_end_point
    maat_db_url           = local.application_data.accounts[local.environment].maat_db_url
    maat_libra_wsdl_url   = local.application_data.accounts[local.environment].maat_libra_wsdl_url
    sentry_env            = local.environment
    db_secret_arn         = "arn:aws:ssm:${local.application_data.accounts[local.environment].region}:${local.env_account_id}:parameter/${local.maatdb_password_secret_name}"
    google_tag_manager_id = "arn:aws:ssm:${local.application_data.accounts[local.environment].region}:${local.env_account_id}:parameter/${local.gtm_id_secret_name}"
  })
  ecs_target_capacity = 100

  # SNS local variables for cloudwatch.tf
  pagerduty_integration_keys     = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
  pagerduty_integration_key_name = local.application_data.accounts[local.environment].pagerduty_integration_key_name
}

#### This file can be used to store locals specific to the member account ####

locals {
  application_test_url = "https://mlra.dev.legalservices.gov.uk"

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

  task_definition = templatefile("task_definition.json", {
    app_name            = local.application_name
    ecr_url             = local.application_data.accounts[local.environment].ecr_url
    docker_image_tag    = local.application_data.accounts[local.environment].docker_image_tag
    region              = local.application_data.accounts[local.environment].region
    maat_api_end_point  = local.application_data.accounts[local.environment].maat_api_end_point
    maat_db_url         = local.application_data.accounts[local.environment].maat_db_url
    maat_db_password    = data.aws_ssm_parameter.db_password.value
    maat_libra_wsdl_url = local.application_data.accounts[local.environment].maat_libra_wsdl_url
    sentry_env          = local.environment
  })

  # SNS local variables for cloudwatch.tf
  pagerduty_integration_keys     = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
  pagerduty_integration_key_name = local.application_data.accounts[local.environment].pagerduty_integration_key_name
}

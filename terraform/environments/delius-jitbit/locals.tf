# This data sources allows us to get the Modernisation Platform account information for use elsewhere
# (when we want to assume a role in the MP, for instance)
data "aws_organizations_organization" "root_account" {}

# Get the environments file from the main repository
data "http" "environments_file" {
  url = "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform/main/environments/${local.application_name}.json"
}

# Retrieve information about the modernisation platform account
data "aws_caller_identity" "modernisation_platform" {
  provider = aws.modernisation-platform
}


locals {

  application_name = "delius-jitbit"

  environment_management = jsondecode(data.aws_secretsmanager_secret_version.environment_management.secret_string)

  # Stores modernisation platform account id for setting up the modernisation-platform provider
  modernisation_platform_account_id = data.aws_ssm_parameter.modernisation_platform_account_id.value

  # This takes the name of the Terraform workspace (e.g. core-vpc-production), strips out the application name (e.g. core-vpc), and checks if
  # the string leftover is `-production`, if it isn't (e.g. core-vpc-non-production => -non-production) then it sets the var to false.
  is-production    = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-production"
  is-preproduction = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-preproduction"
  is-test          = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-test"
  is-development   = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-development"

  # Merge tags from the environment json file with additional ones
  tags = merge(
    jsondecode(data.http.environments_file.response_body).tags,
    { "is-production" = local.is-production },
    { "environment-name" = terraform.workspace },
    { "source-code" = "https://github.com/ministryofjustice/modernisation-platform-environments" }
  )

  environment     = trimprefix(terraform.workspace, "${var.networking[0].application}-")
  vpc_name        = var.networking[0].business-unit
  subnet_set      = var.networking[0].set
  vpc_all         = "${local.vpc_name}-${local.environment}"
  subnet_set_name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}"

  is_live       = [substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-production" || substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-preproduction" ? "live" : "non-live"]
  provider_name = "core-vpc-${local.environment}"

  # environment specfic variables
  # example usage:
  # example_data = local.application_data.accounts[local.environment].example_var
  application_data = fileexists("./application_variables.json") ? jsondecode(file("./application_variables.json")) : {}
  app_data         = jsondecode(file("./application_variables.json"))

  ##
  # Variables used across multiple areas
  ##
  app_url = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"

  ##
  # Variables related to ECS module
  ##
  lb_tg_name = "${local.application_name}-tg-${local.environment}"

  ec2_ingress_rules = {
    "cluster_ec2_lb_ingress" = {
      description     = "Cluster EC2 loadbalancer ingress rule"
      from_port       = 5000
      to_port         = 5000
      protocol        = "tcp"
      cidr_blocks     = []
      security_groups = [aws_security_group.load_balancer_security_group.id]
    }
  }

  ec2_egress_rules = {
    "cluster_ec2_lb_rds_egress" = {
      description     = "Cluster EC2 loadbalancer egress rule"
      from_port       = 1433
      to_port         = 1433
      protocol        = "tcp"
      cidr_blocks     = [data.aws_subnet.data_subnets_a.cidr_block, data.aws_subnet.data_subnets_b.cidr_block, data.aws_subnet.data_subnets_c.cidr_block]
      security_groups = null
    },
    "cluster_ec2_lb_https_egress" = {
      description     = "Allow 443 to internet"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = null
    }
  }

  ecr_repo_name = "delius-jitbit-ecr-repo"
  ecr_uri       = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.ecr_repo_name}"

  task_definition = templatefile("${path.module}/templates/task_definition.json", {
    APP_NAME                                = local.application_name,
    DOCKER_IMAGE                            = "${local.ecr_uri}:latest"
    DATABASE_PASSWORD_CONNECTION_STRING_ARN = aws_secretsmanager_secret.db_app_connection_string.arn
    APP_URL                                 = "https://${local.app_url}/"
  })

  ##
  # Variables used by certificate validation, as part of the load balancer listener, cert and route 53 record configuration
  ##
  domain_types = { for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }

  domain_name_main   = [for k, v in local.domain_types : v.name if k == "modernisation-platform.service.justice.gov.uk"]
  domain_name_sub    = [for k, v in local.domain_types : v.name if k != "modernisation-platform.service.justice.gov.uk"]
  domain_record_main = [for k, v in local.domain_types : v.record if k == "modernisation-platform.service.justice.gov.uk"]
  domain_record_sub  = [for k, v in local.domain_types : v.record if k != "modernisation-platform.service.justice.gov.uk"]
  domain_type_main   = [for k, v in local.domain_types : v.type if k == "modernisation-platform.service.justice.gov.uk"]
  domain_type_sub    = [for k, v in local.domain_types : v.type if k != "modernisation-platform.service.justice.gov.uk"]
}

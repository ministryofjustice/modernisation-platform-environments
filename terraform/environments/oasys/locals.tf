# env independent common vars
# env independent webserver vars

locals {

  ###
  ### env independent common vars
  ###

  application_name = "oasys"
  business_unit    = "hmpps"
  networking_set   = "general"

  accounts = {
    development   = local.oasys_development
    test          = local.oasys_test
    preproduction = local.oasys_preproduction
    production    = local.oasys_production
  }

  account_id         = local.environment_management.account_ids[terraform.workspace]
  environment_config = local.accounts[local.environment]

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

  environment     = trimprefix(terraform.workspace, "${local.application_name}-")
  subnet_set      = local.networking_set
  vpc_all         = "${local.business_unit}-${local.environment}"
  subnet_set_name = "${local.business_unit}-${local.environment}-${local.networking_set}"

  region            = "eu-west-2"
  availability_zone = "eu-west-2a"

  is_live       = [substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-production" || substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-preproduction" ? "live" : "non-live"]
  provider_name = "core-vpc-${local.environment}"

  cidrs = { # this list should be abstracted for multiple environments to use
    # Azure
    noms_live                  = "10.40.0.0/18"
    noms_live_dr               = "10.40.64.0/18"
    noms_mgmt_live             = "10.40.128.0/20"
    noms_mgmt_live_dr          = "10.40.144.0/20"
    noms_transit_live          = "10.40.160.0/20"
    noms_transit_live_dr       = "10.40.176.0/20"
    noms_test                  = "10.101.0.0/16"
    noms_mgmt                  = "10.102.0.0/16"
    noms_test_dr               = "10.111.0.0/16"
    noms_mgmt_dr               = "10.112.0.0/16"
    aks_studio_hosting_live_1  = "10.244.0.0/20"
    aks_studio_hosting_dev_1   = "10.247.0.0/20"
    aks_studio_hosting_ops_1   = "10.247.32.0/20"
    nomisapi_t2_root_vnet      = "10.47.0.192/26"
    nomisapi_t3_root_vnet      = "10.47.0.0/26"
    nomisapi_preprod_root_vnet = "10.47.0.64/26"
    nomisapi_prod_root_vnet    = "10.47.0.128/26"

    # AWS
    cloud_platform = "172.20.0.0/16"
  }

  ec2_common_managed_policies = [
    aws_iam_policy.ec2_common_policy.arn
  ]

  autoscaling_schedules_default = {
    "scale_up" = {
      recurrence = "0 7 * * Mon-Fri"
    }
    "scale_down" = {
      desired_capacity = 0
      recurrence       = "0 19 * * Mon-Fri"
    }
  }

  ###
  ### env independent webserver vars
  ###
  webserver = {
    ami_name = "oasys_webserver_*"
    # branch   = var.BRANCH_NAME # comment in if testing ansible
    # server-type and oasys-environment auto set by module
    autoscaling_schedules = {}
    subnet_name           = "webserver"

    instance = {
      disable_api_termination      = false
      instance_type                = "t3.large"
      key_name                     = aws_key_pair.ec2-user.key_name
      monitoring                   = true
      metadata_options_http_tokens = "optional"
      vpc_security_group_ids       = [aws_security_group.webserver.id]
    }

    user_data_cloud_init = {
      args = {
        lifecycle_hook_name    = "ready-hook"
        branch                 = "main"
        ansible_repo           = "modernisation-platform-configuration-management"
        ansible_repo_basedir   = "ansible"
        # ansible_args           = "--tags ec2provision"
      }
      scripts = [ # it would make sense to have these templates in a common area 
        "ansible-ec2provision.sh.tftpl",
        "post-ec2provision.sh.tftpl"
      ]
      write_files = {}
    }

    # ssm_parameters_prefix     = "webserver/"
    iam_resource_names_prefix = "webserver-asg"

    autoscaling_group = {
      desired_capacity = 1
      max_size         = 2
      min_size         = 0

      # health_check_grace_period = 300
      # health_check_type         = "ELB"
      # force_delete              = true
      # termination_policies      = ["OldestInstance"]
      # target_group_arns         = [] # TODO
      # vpc_zone_identifier       = data.aws_subnets.private.ids
      # wait_for_capacity_timeout = 0

      # this hook is triggered by the post-ec2provision.sh
      # initial_lifecycle_hooks = {
      #   "ready-hook" = {
      #     default_result       = "ABANDON"
      #     heartbeat_timeout    = 7200 # on a good day it takes 30 mins, but can be much longer
      #     lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
      #   }
      # }
      # warm_pool = {
      #   reuse_on_scale_in           = true
      #   max_group_prepared_capacity = 1
      # }
    }
  }
  webserver_tags = {
    description = "oasys webserver"
    component   = "web"
    server-type = "oasys-web"
  }
}

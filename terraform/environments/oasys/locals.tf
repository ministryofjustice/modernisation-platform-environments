# env independent common vars
# env independent webserver vars

locals {

  ###
  ### env independent common vars
  ###

  business_unit  = "hmpps"
  networking_set = "general"

  accounts = {
    development   = local.oasys_development
    test          = local.oasys_test
    preproduction = local.oasys_preproduction
    production    = local.oasys_production
  }

  account_id         = local.environment_management.account_ids[terraform.workspace]
  environment_config = local.accounts[local.environment]

  region            = "eu-west-2"
  availability_zone = "eu-west-2a"

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
        lifecycle_hook_name  = "ready-hook"
        branch               = "main" # if you want to use a branch of ansible
        ansible_repo         = "modernisation-platform-configuration-management"
        ansible_repo_basedir = "ansible"
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
    os-version  = "RHEL 8.5"
  }

  database = {

    instance = {
      disable_api_termination      = false
      instance_type                = "r6i.xlarge"
      key_name                     = aws_key_pair.ec2-user.key_name
      metadata_options_http_tokens = "optional" # the Oracle installer cannot accommodate a token
      monitoring                   = true
      vpc_security_group_ids       = [aws_security_group.data.id]
    }
    autoscaling_schedules = {}
    autoscaling_group = {
      desired_capacity = 1
      max_size         = 2
      min_size         = 0
    }

    user_data_cloud_init = {
      args = {
        lifecycle_hook_name  = "ready-hook"
        branch               = "oasys-db"
        ansible_repo         = "modernisation-platform-configuration-management"
        ansible_repo_basedir = "ansible"
        # ansible_tags           = "ec2provisiondata"
        restored_from_snapshot = false
      }
      scripts = [
        "ansible-ec2provision.sh.tftpl",
      ]
    }

    ebs_volumes = {
      "/dev/sdb" = { # /u01
        size        = 100
        label       = "app"
        type        = "gp3"
        snapshot_id = null
      }
      "/dev/sdc" = { # /u02
        size        = 500
        label       = "app"
        type        = "gp3"
        snapshot_id = null
      }
      "/dev/sde" = { # DATA01
        label       = "data"
        size        = 200
        type        = "gp3"
        snapshot_id = null
      }
      # "/dev/sdf" = {  # DATA02
      #   label = "data"
      #   type = null
      #   snapshot_id = null
      # }
      # "/dev/sdg" = {  # DATA03
      #   label = "data"
      #   type = null
      #   snapshot_id = null
      # }
      # "/dev/sdh" = {  # DATA04
      #   label = "data"
      #   type = null
      #   snapshot_id = null
      # }
      # "/dev/sdi" = {  # DATA05
      #   label = "data"
      #   type = null
      #   snapshot_id = null
      # }
      "/dev/sdj" = { # FLASH01
        label       = "flash"
        type        = "gp3"
        snapshot_id = null
        size        = 50
      }
      # "/dev/sdk" = { # FLASH02
      #   label = "flash"
      #   type = null
      #   snapshot_id = null
      # }
      "/dev/sds" = {
        label       = "swap"
        type        = "gp3"
        snapshot_id = null
        size        = 2
      }
    }

    ebs_volume_config = {
      data = {
        iops       = 3000
        type       = "gp3"
        throughput = 125
        total_size = 200
      }
      flash = {
        iops       = 3000
        type       = "gp3"
        throughput = 125
        total_size = 50
      }
    }

    route53_records = {
      create_internal_record = true
      create_external_record = true
    }

    ssm_parameters = {
      ASMSYS = {
        random = {
          length  = 30
          special = false
        }
        description = "ASMSYS password"
      }
      ASMSNMP = {
        random = {
          length  = 30
          special = false
        }
        description = "ASMSNMP password"
      }
    }
    ssm_parameters_prefix     = "database/"
    iam_resource_names_prefix = "ec2-database"
    subnet_id                 = module.environment.subnet["data"][local.availability_zone].id # for ec2_instance
    subnet_ids                = module.environment.subnet["data"][local.availability_zone].id # for ASG
  }
  database_tags = {
    component            = "data"
    os-type              = "Linux"
    os-major-version     = 8
    os-version           = "RHEL 8.5"
    licence-requirements = "Oracle Database"
    "Patch Group"        = "RHEL"
  }

  security_group_cidrs_devtest = {
    ssh = module.ip_addresses.azure_fixngo_cidrs.devtest
    https = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidrs.trusted_moj_enduser_internal,
    ])
    http7xxx = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
    ])
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidr.aws_analytical_platform_aggregate,
      module.ip_addresses.azure_studio_hosting_cidrs.devtest,
      module.ip_addresses.azure_nomisapi_cidrs.devtest,
    ])
    oracle_oem_agent = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
    ])
  }

  security_group_cidrs_preprod_prod = {
    ssh = module.ip_addresses.azure_fixngo_cidrs.prod
    https = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidrs.trusted_moj_enduser_internal,
    ])
    http7xxx = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
    ])
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidr.aws_analytical_platform_aggregate,
      module.ip_addresses.azure_studio_hosting_cidrs.prod,
      module.ip_addresses.azure_nomisapi_cidrs.prod,
    ])
    oracle_oem_agent = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
    ])
  }

  security_group_cidrs_by_environment = {
    development   = local.security_group_cidrs_devtest
    test          = local.security_group_cidrs_devtest
    preproduction = local.security_group_cidrs_preprod_prod
    production    = local.security_group_cidrs_preprod_prod
  }

  security_group_cidrs = local.security_group_cidrs_by_environment[local.environment]

  lb_defaults = {
    enable_delete_protection = false
    idle_timeout             = "60"
    public_subnets           = module.environment.subnets["public"].ids
    force_destroy_bucket     = true
    internal_lb              = true
    tags                     = local.tags
    security_groups          = [aws_security_group.public.id]
  }

  lbs = {
    common = {}

    development = {
      oasys-public = {
        internal_lb = false
      }
    }

    test = {}

    preproduction = {}

    production = {}
  }

  lb_listener_defaults = {

    oasys_public = {
      lb_application_name = "oasys-public"
      asg_instance        = "webservers"
    }

    route53 = {
      route53_records = {
        "web.oasys" = {
          account                = "core-vpc"
          zone_id                = module.environment.route53_zones[module.environment.domains.public.business_unit_environment].zone_id
          evaluate_target_health = true
        }
      }
    }

    https = {
      port             = 443
      protocol         = "HTTPS"
      ssl_policy       = "ELBSecurityPolicy-2016-08"
      certificate_arns = [module.acm_certificate["star.${module.environment.domains.public.application_environment}"].arn]
      default_action = {
        type = "fixed-response"
        fixed_response = {
          content_type = "text/plain"
          message_body = "Not implemented"
          status_code  = "501"
        }
      }

      rules = {
        forward-http-8080 = {
          priority = 100
          actions = [{
            type              = "forward"
            target_group_name = "http-8080"
          }]
          conditions = [
            {
              host_header = {
                values = ["web.oasys.${module.environment.vpc_name}.modernisation-platform.service.justice.gov.uk"]
              }
            },
            {
              path_pattern = {
                values = ["/"]
              }
          }]
        }
      }
    }
  }

  lb_listeners = {

    development = {
      oasys-public = merge(
        local.lb_listener_defaults.https,
        local.lb_listener_defaults.oasys_public,
        local.lb_listener_defaults.route53,
      )
    }

    test          = {}
    preproduction = {}
    production    = {}
  }

  acm_certificates = {

    # Certificates common to all environments
    common = {
      # e.g. star.nomis.hmpps-development.modernisation-platform.service.justice.gov.uk
      "star.${module.environment.domains.public.application_environment}" = {
        # domain_name limited to 64 chars so put it in the san instead
        domain_name             = module.environment.domains.public.modernisation_platform
        subject_alternate_names = ["*.${module.environment.domains.public.application_environment}"]
        validation = {
          "${module.environment.domains.public.modernisation_platform}" = {
            account   = "core-network-services"
            zone_name = "${module.environment.domains.public.modernisation_platform}."
          }
          "*.${module.environment.domains.public.application_environment}" = {
            account   = "core-vpc"
            zone_name = "${module.environment.domains.public.business_unit_environment}."
          }
        }
        tags = {
          description = "wildcard cert for ${module.environment.domains.public.application_environment} domain"
        }
      }
    }
    # Alarms for certificates
    cloudwatch_metric_alarms_acm = {}

    # Environment specific certificates
    development   = {}
    test          = {}
    preproduction = {}
    production    = {}
  }
}
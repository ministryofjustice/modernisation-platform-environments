# env independent common vars
# env independent webserver vars

locals {

  baseline_s3_buckets = {
    (terraform.workspace) = {
      iam_policies = module.baseline_presets.s3_iam_policies
    }
  }
  ###
  ### env independent common vars
  ###

  business_unit  = "hmpps"
  networking_set = "general"

  accounts = {
    development   = local.development_config
    test          = local.test_config
    preproduction = local.preproduction_config
    production    = local.production_config
  }

  environment_config = local.accounts[local.environment]

  region            = "eu-west-2"
  availability_zone = "eu-west-2a"

  ###
  ### env independent webserver vars
  ###
  webserver_a = {
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name                  = "oasys_webserver_release_*"
      ssm_parameters_prefix     = "ec2-web/"
      iam_resource_names_prefix = "ec2-web"
      availability_zone         = "${local.region}a"
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      monitoring             = true
      vpc_security_group_ids = ["private_web"]
    })
    cloudwatch_metric_alarms = {}
    user_data_cloud_init     = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags
    autoscaling_schedules = {
      "scale_up" = {
        recurrence = "0 5 * * Mon-Fri"
      }
      "scale_down" = {
        desired_capacity = 0
        recurrence       = "0 19 * * Mon-Fri"
      }
    }
    autoscaling_group = module.baseline_presets.ec2_autoscaling_group.default
    lb_target_groups = {
      pv-http-8080 = local.target_group_http_8080
      pb-http-8080 = local.target_group_http_8080
    }
    tags = {
      component         = "web"
      description       = "${local.environment} ${local.application_name} web"
      os-type           = "Linux"
      os-major-version  = 7
      os-version        = "RHEL 7.9"
      "Patch Group"     = "RHEL"
      server-type       = "${local.application_name}-web"
      monitored         = true
      oasys-environment = local.environment
      environment-name  = terraform.workspace
      #oracle-db-hostname = "T2ODL0009.azure.noms.root"
      oracle-db-sid = "OASPROD" # for each env using azure DB will need to be OASPROD
    }
  }
  webserver_b = merge(local.webserver_a, {
    config = merge(local.webserver_a.config, {
      availability_zone = "${local.region}b"
    })
  })
  target_group_http_8080 = {
    port                 = 8080
    protocol             = "HTTP"
    target_type          = "instance"
    deregistration_delay = 30
    health_check = {
      enabled             = true
      interval            = 30
      healthy_threshold   = 3
      matcher             = "200-399"
      path                = "/"
      port                = 8080
      timeout             = 5
      unhealthy_threshold = 5
    }
    stickiness = {
      enabled = true
      type    = "lb_cookie"
    }
  }

  database_a = {
    config = merge(module.baseline_presets.ec2_instance.config.db, {
      ami_name                  = "oasys_oracle_db_release_2023-06-26T10-16-03.670Z"
      ami_owner                 = "self"
      availability_zone         = "${local.region}a"
      instance_profile_policies = flatten([
        module.baseline_presets.ec2_instance.config.db,
        module.baseline_presets.iam_policies.Ec2OracleEnterpriseManagerPolicy
      ])
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default_db, {
      tags = {
        backup-plan = "daily-and-weekly"
      }
    })
    autoscaling_schedules = {}
    autoscaling_group     = module.baseline_presets.ec2_autoscaling_group.default
    user_data_cloud_init  = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags
    ebs_volumes = {
      "/dev/sdb" = { # /u01
        size  = 100
        label = "app"
        type  = "gp3"
      }
      "/dev/sdc" = { # /u02
        size  = 500
        label = "app"
        type  = "gp3"
      }
      "/dev/sde" = { # DATA01
        label = "data"
        size  = 500
        type  = "gp3"
      }
      # "/dev/sdf" = {  # DATA02
      #   label = "data"
      #   type = null
      # }
      # "/dev/sdg" = {  # DATA03
      #   label = "data"
      #   type = null
      # }
      # "/dev/sdh" = {  # DATA04
      #   label = "data"
      #   type = null
      # }
      # "/dev/sdi" = {  # DATA05
      #   label = "data"
      #   type = null
      # }
      "/dev/sdj" = { # FLASH01
        label = "flash"
        type  = "gp3"
        size  = 50
      }
      # "/dev/sdk" = { # FLASH02
      #   label = "flash"
      #   type = null
      # }
      "/dev/sds" = {
        label = "swap"
        type  = "gp3"
        size  = 2
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
    route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external
    ssm_parameters = {
      asm-passwords = {}
    }
    # Example target group setup below
    lb_target_groups = {}
    tags = {
      backup                                  = "false" # opt out of mod platform default backup plan
      component                               = "data"
      oracle-sids                             = "OASPROD BIPINFRA"
      os-type                                 = "Linux"
      os-major-version                        = 8
      os-version                              = "RHEL 8.5"
      licence-requirements                    = "Oracle Database"
      "Patch Group"                           = "RHEL"
      server-type                             = "${local.application_name}-db"
      description                             = "${local.environment} ${local.application_name} database"
      monitored                               = true
      "${local.application_name}-environment" = local.environment
      environment-name                        = terraform.workspace # used in provisioning script to select group vars
    }
  }
  database_b = merge(local.database_a, {
    config = merge(local.database_a.config, {
      availability_zone = "${local.region}b"
    })
  })


  bip_a = {
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name                  = "oasys_bip_release_2023-06-08T15-17-45.964Z"
      ssm_parameters_prefix     = "ec2-web/"
      iam_resource_names_prefix = "ec2-web"
      availability_zone         = "${local.region}a"
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      instance_type          = "t3.xlarge"
      monitoring             = true
      vpc_security_group_ids = ["bip"]
      tags = {
        backup-plan = "daily-and-weekly"
      }
    })
    cloudwatch_metric_alarms = {}
    user_data_cloud_init     = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags
    autoscaling_schedules    = module.baseline_presets.ec2_autoscaling_schedules.working_hours
    autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
      desired_capacity = 2
      max_size         = 2
    })
    lb_target_groups = {}
    tags = {
      backup            = "false" # opt out of mod platform default backup plan
      component         = "bip"
      description       = "${local.environment} ${local.application_name} bip"
      os-type           = "Linux"
      os-major-version  = 7
      os-version        = "RHEL 7.9"
      "Patch Group"     = "RHEL"
      server-type       = "${local.application_name}-bip"
      monitored         = true
      oasys-environment = local.environment
      environment-name  = terraform.workspace
    }
  }
  bip_b = merge(local.bip_a, {
    config = merge(local.bip_a.config, {
      availability_zone = "${local.region}b"
    })
  })

  baseline_secretsmanager_secrets = {}

  public_key_data = jsondecode(file("./files/bastion_linux.json"))
}
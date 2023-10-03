#### This file can be used to store locals specific to the member account ####

locals {
  business_unit = var.networking[0].business-unit

  environment_configs = {
    development   = local.development_config
    test          = local.test_config
    preproduction = local.preproduction_config
    production    = local.production_config
  }
  baseline_environment_config = local.environment_configs[local.environment]
  environment_config          = local.environment_configs[local.environment]
  ndh_secrets = [
    "ndh_admin_user",
    "ndh_admin_pass",
    "ndh_domain_name",
    "ndh_ems_host_a",
    "ndh_ems_host_b",
    "ndh_app_host_a",
    "ndh_app_host_b",
    "ndh_ems_port_1",
    "ndh_ems_port_2",
    "ndh_host_os",
    "ndh_host_os_version",
    "ndh_harkemsadmin_ssl_pass",
  ]

  baseline_ssm_parameters = {}

  baseline_s3_buckets = {
    s3-bucket = {
      iam_policies = module.baseline_presets.s3_iam_policies
    }
  }
  baseline_route53_zones = {}

  ndh_app_a = {
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name = "nomis_data_hub_rhel_7_9_app_release_2023-05-02T00-00-47.783Z"
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      vpc_security_group_ids       = ["private"]
      tags = {
        backup-plan = "daily-and-weekly"
      }
    })
    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
    tags = {
      description = "RHEL7.9 NDH App"
      component   = "ndh"
      server-type = "ndh-app"
      monitored   = false
    }
  }

  ndh_ems_a = {
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name = "nomis_data_hub_rhel_7_9_ems_test_2023-04-02T00-00-21.281Z"
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      vpc_security_group_ids       = ["private"]
      tags = {
        backup-plan = "daily-and-weekly"
      }
    })
    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
    tags = {
      description = "RHEL7.9 NDH ems"
      component   = "ndh"
      server-type = "ndh-ems"
      monitored   = false
    }
  }

  management_server_2022 = {
    # ami has unwanted ephemeral device, don't copy all the ebs_volumess
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name                      = "hmpps_windows_server_2022_release_2023-*"
      ebs_volumes_copy_all_from_ami = false
      user_data_raw                 = base64encode(file("./templates/ndh-user-data.yaml"))
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      vpc_security_group_ids = ["private"]
      tags = {
        backup-plan = "daily-and-weekly"
      }
    })
    ebs_volumes = {
      "/dev/sda1" = { type = "gp3", size = 100 }
    }
    tags = {
      description = "Windows Server 2022 Management server for NDH"
      os-type     = "Windows"
      component   = "managementserver"
      server-type = "ndh-management-server"
    }
  }
}

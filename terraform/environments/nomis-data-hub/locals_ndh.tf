# configuration defaults for ndh

locals {
  ndh_secretsmanager_secrets = {
    secrets = {
      shared = { description = "NDH secrets for both ems and app components" }
    }
  }

  ndh_app_a = {
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name = "nomis_data_hub_rhel_7_9_app_release_2023-05-02T00-00-47.783Z"
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      vpc_security_group_ids = ["ndh_app"]
      tags = {
        backup-plan = "daily-and-weekly"
      }
    })
    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
    tags = {
      description         = "RHEL7.9 NDH App"
      component           = "ndh"
      server-type         = "ndh-app"
      monitored           = false
      instance-scheduling = "skip-scheduling"
    }
  }

  ndh_ems_a = {
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name = "nomis_data_hub_rhel_7_9_ems_test_2023-04-02T00-00-21.281Z"
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      vpc_security_group_ids = ["ndh_ems"]
      tags = {
        backup-plan = "daily-and-weekly"
      }
    })
    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
    tags = {
      description         = "RHEL7.9 NDH ems"
      component           = "ndh"
      server-type         = "ndh-ems"
      monitored           = false
      instance-scheduling = "skip-scheduling"
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
      vpc_security_group_ids = ["management_server"]
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

# nomis-preproduction environment settings
locals {

  # baseline config
  preproduction_config = {
    baseline_ec2_instances = {
      pp-csr-w-7-b = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "pp-csr-w-7-b"
          ami_owner                     = "self"
          availability_zone             = "${local.region}b"
          ebs_volumes_copy_all_from_ami = false
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type           = "m5.2xlarge"
          disable_api_termination = true
          monitoring              = true
          vpc_security_group_ids  = ["migration-web-sg", "domain-controller"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
        }
      }

      pp-csr-w-8-b-2 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "pp-csr-w-8-b"
          ami_owner                     = "self"
          availability_zone             = "${local.region}b"
          ebs_volumes_copy_all_from_ami = false
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type           = "m5.2xlarge"
          disable_api_termination = true
          monitoring              = true
          vpc_security_group_ids  = ["migration-web-sg", "domain-controller"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 200 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
        }
        tags = {
            description = "copy of PPCWW00008, fully converted, ready for config files"
            os-type     = "Windows"
            component   = "web" / "app" 
        }
      }
    }

    baseline_ec2_autoscaling_groups = {
      prepprod-tst-1 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2023-*" # Microsoft Windows Server 2019 Base
          ami_owner                     = "754260907303"
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/test-user-data.yaml"))
          instance_profile_policies     = concat(module.baseline_presets.ec2_instance.config.default.instance_profile_policies, ["CSRWebServerPolicy"])
        })

        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["migration-web-sg", "domain-controller"]
          instance_type          = "t3.medium"

        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 256 }
        }
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0 # set to 0 while testing
        })
        tags = {
          description = "Test Windows Web Server 2019"
          os-type     = "Windows"
          component   = "Test"
          server-type = "test-windows-server"
        }
      }
    }
    baseline_route53_zones = {
      "hmpps-preproduction.modernisation-platform.service.justice.gov.uk" = {
        records = [
        ]
      }
    }
  }
}




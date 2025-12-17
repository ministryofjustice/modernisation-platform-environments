# Terraform configuration data for the stage environment in delius-mis preproduction account

locals {
  environment_config_stage = {
    legacy_engineering_vpc_cidr            = "10.160.98.0/25"
    legacy_counterpart_vpc_cidr            = "10.160.32.0/20"
    ad_domain_name                         = "delius-mis-stage.internal"
    ec2_user_ssh_key                       = file("${path.module}/files/.ssh/${terraform.workspace}/ec2-user.pub")
    migration_environment_full_name        = "del-stage"
    migration_environment_abbreviated_name = "del"
    migration_environment_short_name       = "stage"
    migration_environment_private_cidr     = ["10.160.32.0/22", "10.160.36.0/22", "10.160.40.0/22"]
    migration_environment_db_cidr          = ["10.162.110.0/25", "10.162.108.0/24", "10.162.109.0/24"]
    cloudwatch_alarm_schedule              = true
    cloudwatch_alarm_disable_time          = "20:45"
    cloudwatch_alarm_enable_time           = "06:15"
    cloudwatch_alarm_disable_weekend       = true
  }

  bastion_config_stage = {
    extra_user_data_content = "yum install -y openldap-clients"
  }

  bcs_config_stage = {
    instance_count = 0
    ami_name       = "delius_mis_windows_server_patch_2024-02-07T11-03-13.202Z"
    ebs_volumes = {
      "/dev/sda1" = { label = "root", size = 150 }
      "/dev/xvdf" = { label = "data", size = 300 }
    }

    ebs_volumes_config = {
      data = {
        iops       = 3000
        throughput = 125
        type       = "gp3"
      }
      root = {
        iops       = 3000
        throughput = 125
        type       = "gp3"
      }
    }

    instance_config = {
      associate_public_ip_address  = false
      disable_api_termination      = false
      disable_api_stop             = false
      instance_type                = "t3.xlarge"
      metadata_endpoint_enabled    = "enabled"
      key_name                     = null
      metadata_options_http_tokens = "required"
      monitoring                   = true
      ebs_block_device_inline      = true

      private_dns_name_options = {
        enable_resource_name_dns_aaaa_record = false
        enable_resource_name_dns_a_record    = true
        hostname_type                        = "resource-name"
      }

      tags = merge(
        local.tags,
        { backup = true }
      )
    }
  }

  bps_config_stage = {
    instance_count = 0
    ami_name       = "delius_mis_windows_server_patch_2024-02-07T11-03-13.202Z"
    ebs_volumes = {
      "/dev/sda1" = { label = "root", size = 150 }
      "/dev/xvdf" = { label = "data", size = 300 }
    }

    ebs_volumes_config = {
      data = {
        iops       = 3000
        throughput = 125
        type       = "gp3"
      }
      root = {
        iops       = 3000
        throughput = 125
        type       = "gp3"
      }
    }

    instance_config = {
      associate_public_ip_address  = false
      disable_api_termination      = false
      disable_api_stop             = false
      instance_type                = "t3.xlarge"
      metadata_endpoint_enabled    = "enabled"
      key_name                     = null
      metadata_options_http_tokens = "required"
      monitoring                   = true
      ebs_block_device_inline      = true

      private_dns_name_options = {
        enable_resource_name_dns_aaaa_record = false
        enable_resource_name_dns_a_record    = true
        hostname_type                        = "resource-name"
      }

      tags = merge(
        local.tags,
        { backup = true }
      )
    }
  }

  bws_config_stage = {
    instance_count = 0
    ami_name       = "delius_mis_windows_server_patch_2024-02-07T11-03-13.202Z"
    ebs_volumes = {
      "/dev/sda1" = { label = "root", size = 150 }
      "/dev/xvdf" = { label = "data", size = 300 }
    }

    ebs_volumes_config = {
      data = {
        iops       = 3000
        throughput = 125
        type       = "gp3"
      }
      root = {
        iops       = 3000
        throughput = 125
        type       = "gp3"
      }
    }

    instance_config = {
      associate_public_ip_address  = false
      disable_api_termination      = false
      disable_api_stop             = false
      instance_type                = "t3.xlarge"
      metadata_endpoint_enabled    = "enabled"
      key_name                     = null
      metadata_options_http_tokens = "required"
      monitoring                   = true
      ebs_block_device_inline      = true

      private_dns_name_options = {
        enable_resource_name_dns_aaaa_record = false
        enable_resource_name_dns_a_record    = true
        hostname_type                        = "resource-name"
      }

      tags = merge(
        local.tags,
        { backup = true }
      )
    }
  }

  dis_config_stage = {
    instance_count    = 1
    ami_name          = "delius_mis_windows_server_patch_2025-10-01T13-00-02.504Z"
    computer_name     = "NDMIS-STG-DIS" # 15 char limit
    powershell_branch = "main"

    ebs_volumes = {
      "/dev/sda1" = { label = "root", size = 100 }
      "/dev/xvdf" = { label = "data", size = 300 }
    }

    ebs_volumes_config = {
      data = {
        iops       = 3000
        throughput = 125
        type       = "gp3"
      }
      root = {
        iops       = 3000
        throughput = 125
        type       = "gp3"
      }
    }

    instance_config = {
      associate_public_ip_address  = false
      disable_api_termination      = false
      disable_api_stop             = false
      instance_type                = "t3.xlarge"
      metadata_endpoint_enabled    = "enabled"
      key_name                     = null
      metadata_options_http_tokens = "required"
      monitoring                   = true
      ebs_block_device_inline      = true

      private_dns_name_options = {
        enable_resource_name_dns_aaaa_record = false
        enable_resource_name_dns_a_record    = true
        hostname_type                        = "resource-name"
      }

      tags = merge(
        local.tags,
        { backup = true }
      )
    }
  }

  # new DFI instance config to differentiate from DIS
  dfi_config_stage = {
    instance_count = 0
    ami_name       = "delius_mis_windows_server_patch_2025-07-09T12-56-15.901Z"
    ebs_volumes = {
      "/dev/sda1" = { label = "root", size = 150 } # root volume
      "xvdd"      = { label = "data", size = 300 } # D:\ App drive
    }
    ebs_volumes_config = {
      data = {
        iops       = 3000
        throughput = 125
        type       = "gp3"
      }
      root = {
        iops       = 3000
        throughput = 125
        type       = "gp3"
      }
    }
    instance_config = {
      associate_public_ip_address  = false
      disable_api_termination      = false
      disable_api_stop             = false
      instance_type                = "t2.xlarge" # see TM-1305
      metadata_endpoint_enabled    = "enabled"
      key_name                     = null
      metadata_options_http_tokens = "required"
      monitoring                   = false
      ebs_block_device_inline      = true

      private_dns_name_options = {
        enable_resource_name_dns_aaaa_record = false
        enable_resource_name_dns_a_record    = true
        hostname_type                        = "resource-name"
      }

      tags = merge(
        local.tags,
        { backup = true
        }
      )
    }
    # Load balancer configuration for DFI
    lb_target_config = {
      endpoint             = "ndl-dfi"
      port                 = 8080
      health_check_path    = "/DataServices/"
      health_check_matcher = "200,302,301"
    }
  }

  # base config for each database
  base_db_config_stage = {
    instance_type  = "t3.large"
    ami_name_regex = "^delius_core_ol_8_5_oracle_db_19c_patch_2024-01-31T16-06-00.575Z"

    instance_policies = {
      "business_unit_kms_key_access" = aws_iam_policy.business_unit_kms_key_access
    }

    ebs_volumes = {
      "/dev/sdb" = { label = "app", size = 200 } # /u01
      "/dev/sdc" = { label = "app", size = 100 } # /u02
      "/dev/sde" = { label = "data" }            # DATA
      "/dev/sdf" = { label = "flash" }           # FLASH
      "/dev/sds" = { label = "swap" }
    }
    ebs_volume_config = {
      app = {
        iops       = 3000
        throughput = 125
        type       = "gp3"
      }
      data = {
        iops       = 3000
        throughput = 125
        type       = "gp3"
        total_size = 100
      }
      flash = {
        iops       = 3000
        throughput = 125
        type       = "gp3"
        total_size = 100
      }
    }
    ansible_user_data_config = {
      branch               = "main"
      ansible_repo         = "modernisation-platform-configuration-management"
      ansible_repo_basedir = "ansible"
      ansible_args         = "oracle_19c_install"
    }
  }


  # BOE DB config
  boe_db_config_stage = {
    instance_type  = "m7i.large"
    instance_count = 1
    ami_name_regex = "^delius_core_ol_8_5_oracle_db_19c_patch_2024-01-31T16-06-00.575Z"

    instance_policies = {
      "business_unit_kms_key_access" = aws_iam_policy.business_unit_kms_key_access
    }

    ebs_volumes = {
      "/dev/sdb" = { label = "app", size = 200 } # /u01
      "/dev/sdc" = { label = "app", size = 100 } # /u02
      "/dev/sde" = { label = "data" }            # DATA
      "/dev/sdf" = { label = "flash" }           # FLASH
      "/dev/sds" = { label = "swap" }
    }
    ebs_volume_config = {
      app = {
        iops       = 3000
        throughput = 125
        type       = "gp3"
      }
      data = {
        iops       = 3000
        throughput = 500
        type       = "gp3"
        total_size = 200
      }
      flash = {
        iops       = 3000
        throughput = 500
        type       = "gp3"
        total_size = 200
      }
    }
    ansible_user_data_config = {
      branch               = "main"
      ansible_repo         = "modernisation-platform-configuration-management"
      ansible_repo_basedir = "ansible"
      ansible_args         = "oracle_19c_install"
    }
  }


  # DSD DB config
  dsd_db_config_stage = {
    instance_type  = "m7i.large"
    instance_count = 1
    ami_name_regex = "^delius_core_ol_8_5_oracle_db_19c_patch_2024-01-31T16-06-00.575Z"

    instance_policies = {
      "business_unit_kms_key_access" = aws_iam_policy.business_unit_kms_key_access
    }

    ebs_volumes = {
      "/dev/sdb" = { label = "app", size = 200 } # /u01
      "/dev/sdc" = { label = "app", size = 100 } # /u02
      "/dev/sde" = { label = "data" }            # DATA
      "/dev/sdf" = { label = "flash" }           # FLASH
      "/dev/sds" = { label = "swap" }
    }
    ebs_volume_config = {
      app = {
        iops       = 3000
        throughput = 125
        type       = "gp3"
      }
      data = {
        iops       = 3000
        throughput = 500
        type       = "gp3"
        total_size = 200
      }
      flash = {
        iops       = 3000
        throughput = 500
        type       = "gp3"
        total_size = 200
      }
    }
    ansible_user_data_config = {
      branch               = "main"
      ansible_repo         = "modernisation-platform-configuration-management"
      ansible_repo_basedir = "ansible"
      ansible_args         = "oracle_19c_install"
    }
  }


  # MIS DB config
  mis_db_config_stage = {
    instance_type  = "r7i.4xlarge" # manually turn off when not in use to save costs
    instance_count = 1
    # most recent 8_5 image, ami builder needs fixing after this
    ami_name_regex = "^delius_core_ol_8_5_oracle_db_19c_patch_2025-03-02T00-00-34.442Z"

    instance_policies = {
      "business_unit_kms_key_access" = aws_iam_policy.business_unit_kms_key_access
    }

    ebs_volumes = {
      "/dev/sdb" = { label = "app", size = 200 } # /u01
      "/dev/sdc" = { label = "app", size = 100 } # /u02
      "/dev/sdd" = { label = "data" }            # DATA
      "/dev/sde" = { label = "data" }            # DATA
      "/dev/sdf" = { label = "data" }            # DATA
      "/dev/sdg" = { label = "data" }            # DATA
      "/dev/sdh" = { label = "data" }            # DATA
      "/dev/sdi" = { label = "flash" }           # FLASH
      "/dev/sdj" = { label = "flash" }           # FLASH
      "/dev/sdk" = { label = "flash" }           # FLASH
      "/dev/sdl" = { label = "flash" }           # FLASH
      "/dev/sds" = { label = "swap" }
    }
    ebs_volume_config = {
      app = {
        iops       = 3000
        throughput = 125
        type       = "gp3"
      }
      data = {
        iops       = 5000
        throughput = 500
        type       = "gp3"
        total_size = 6000
      }
      flash = {
        iops       = 3000
        throughput = 500
        type       = "gp3"
        total_size = 4000
      }
    }
    ansible_user_data_config = {
      branch               = "main"
      ansible_repo         = "modernisation-platform-configuration-management"
      ansible_repo_basedir = "ansible"
      ansible_args         = "oracle_19c_install"
    }

    enable_cloudwatch_alarms = false
  }

  fsx_config_stage = {
    storage_capacity     = 200
    throughtput_capacity = 16
  }

  dfi_report_bucket_config_stage = null

  lb_config_stage = null
}

# Terraform configuration data for the stage environment in delius-mis preproduction account

locals {
  environment_config_stage = {
    # comment in below after trust secret set
    #ad_trust_domain_name                   = "azure.hmpp.root"

    legacy_engineering_vpc_cidr            = "10.160.98.0/25"
    legacy_counterpart_vpc_cidr            = "10.160.32.0/20"
    ad_domain_name                         = "delius-mis-stage.internal"
    ad_trust_dc_cidrs                      = module.ip_addresses.active_directory_cidrs.hmpp.domain_controllers
    ad_trust_dns_ip_addrs                  = module.ip_addresses.mp_ips.ad_fixngo_hmpp_domain_controllers
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

  boe_efs_config_stage = {
    availability_zone_name = "eu-west-2a"
    mount_targets_subnet_ids = {
      single-az = data.aws_subnets.shared-private-a.ids[0]
    }
    # For multi-az, use:
    # availability_zone_name = null
    # mount_targets_subnet_ids = {
    #   multi-az-a = data.aws_subnets.shared-private-a.ids[0]
    #   multi-az-b = data.aws_subnets.shared-private-b.ids[0]
    #   multi-az-c = data.aws_subnets.shared-private-c.ids[0]
    # }
  }
  bcs_config_stage = {
    instance_count = 1
    ami_name       = "base_rhel_8_5_2023-07-01T00-00-47.469Z"
    ami_owner      = local.environment_management.account_ids["core-shared-services-production"]
    ansible_branch = "TM-1884/delius-mis/configure-stage"
    ebs_volumes = {
      "/dev/sda1" = { label = "root", size = 150, type = "gp3" } # 100GB would be OK
      "/dev/sdb"  = { label = "data", size = 100, type = "gp3" }
      "/dev/sdc"  = { label = "data", size = 100, type = "gp3" }
      "/dev/sds"  = { label = "swap", size = 8, type = "gp3" }
    }
    ebs_volumes_config = {}

    instance_config = {
      associate_public_ip_address  = false
      disable_api_termination      = false
      disable_api_stop             = false
      instance_type                = "m6i.xlarge"
      metadata_endpoint_enabled    = "enabled"
      key_name                     = null
      metadata_options_http_tokens = "required"
      monitoring                   = true
      ebs_block_device_inline      = true

      tags = merge(
        local.tags,
        { backup = true }
      )
    }
  }

  bps_config_stage = {
    instance_count = 1
    ami_name       = "base_rhel_8_5_2023-07-01T00-00-47.469Z"
    ami_owner      = local.environment_management.account_ids["core-shared-services-production"]
    ansible_branch = "TM-1884/delius-mis/configure-stage"
    ebs_volumes = {
      "/dev/sda1" = { label = "root", size = 100, type = "gp3" }
      "/dev/sdb"  = { label = "data", size = 100, type = "gp3" }
      "/dev/sdc"  = { label = "data", size = 100, type = "gp3" }
      "/dev/sds"  = { label = "swap", size = 8, type = "gp3" }
    }
    ebs_volumes_config = {}

    instance_config = {
      associate_public_ip_address  = false
      disable_api_termination      = false
      disable_api_stop             = false
      instance_type                = "r6i.2xlarge"
      metadata_endpoint_enabled    = "enabled"
      key_name                     = null
      metadata_options_http_tokens = "required"
      monitoring                   = true
      ebs_block_device_inline      = true

      tags = merge(
        local.tags,
        { backup = true }
      )
    }
  }

  bws_config_stage = {
    instance_count = 1
    ami_name       = "base_rhel_8_5_2023-07-01T00-00-47.469Z"
    ami_owner      = local.environment_management.account_ids["core-shared-services-production"]
    ansible_branch = "TM-1884/delius-mis/configure-stage"
    ebs_volumes = {
      "/dev/sda1" = { label = "root", size = 100, type = "gp3" }
      "/dev/sdb"  = { label = "data", size = 100, type = "gp3" }
      "/dev/sdc"  = { label = "data", size = 100, type = "gp3" }
      "/dev/sds"  = { label = "swap", size = 8, type = "gp3" }
    }
    ebs_volumes_config = {}

    instance_config = {
      associate_public_ip_address  = false
      disable_api_termination      = false
      disable_api_stop             = false
      instance_type                = "r6i.xlarge"
      metadata_endpoint_enabled    = "enabled"
      key_name                     = null
      metadata_options_http_tokens = "required"
      monitoring                   = true
      ebs_block_device_inline      = true

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
      instance_type                = "r6i.4xlarge" # Legacy is m5.8xlarge but AWS recommends r6i.4xlarge
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
    lb_target_config = {
      endpoint             = "ndl-dis"
      port                 = 8080
      health_check_path    = "/BOE/CMC/"
      health_check_matcher = "200,302,301"
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

  dfi_report_bucket_config_stage = {
    bucket_policy_enabled = true
  }

  lb_config_stage = {
    bucket_policy_enabled = true
  }

  datasync_config_stage = {
    source_s3_bucket_arn = "arn:aws:s3:::eu-west-2-delius-stage-dfi-extracts"
  }
}

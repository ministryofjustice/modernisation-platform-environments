# Terraform configuration data for environments in delius-mis development account

locals {
  environment_config_dev = {
    legacy_engineering_vpc_cidr            = "10.161.98.0/25"
    legacy_counterpart_vpc_cidr            = "10.162.32.0/20"
    ad_domain_name                         = "delius-mis-dev.internal"
    ec2_user_ssh_key                       = file("${path.module}/files/.ssh/${terraform.workspace}/ec2-user.pub")
    migration_environment_full_name        = "dmd-mis-dev"
    migration_environment_abbreviated_name = "dmd"
    migration_environment_short_name       = "mis-dev"
    migration_environment_private_cidr     = ["10.162.32.0/22", "10.162.36.0/22", "10.162.40.0/22"]
    migration_environment_db_cidr          = ["10.162.110.0/25", "10.162.108.0/24", "10.162.109.0/24"]
    cloudwatch_alarm_schedule              = true
    cloudwatch_alarm_disable_time          = "20:45"
    cloudwatch_alarm_enable_time           = "06:15"
    cloudwatch_alarm_disable_weekend       = true
  }

  bastion_config_dev = {
    extra_user_data_content = "yum install -y openldap-clients"
  }

  boe_efs_config_dev = {
    availability_zone_name = "eu-west-2a"
    mount_targets_subnet_ids = {
      single-az = data.aws_subnets.shared-private-a.ids[0]
    }
    # For multi-az, use:
    # availability_zone_name = null
    # mount_targets_subnet_ids = {
    #   multi-az-a = data.aws_subnets.shared-private-a.ids[0]
    #   multi-az-b = data.aws_subnets.shared-private-b.ids[0]
    #   multi-az-c = data.aws_subnets.shared-private-c.ids[0]
    # }
  }
  bcs_config_dev = {
    instance_count = 0
    ami_name       = "base_rhel_8_5_2023-07-01T00-00-47.469Z"
    ami_owner      = local.environment_management.account_ids["core-shared-services-production"]
    ansible_branch = "TM-1748/ndmis/rebuild-bip-as-linux-v2"
    ebs_volumes = {
      "/dev/sda1" = { label = "root", size = 150, type = "gp3" }
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

  bps_config_dev = {
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

      tags = merge(
        local.tags,
        { backup = true }
      )
    }
  }

  bws_config_dev = {
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

      tags = merge(
        local.tags,
        { backup = true }
      )
    }
  }

  dis_config_dev = {
    instance_count = 1
    ami_name       = "delius_mis_windows_server_patch_2025-10-01T13-00-02.504Z"
    ebs_volumes = {
      "/dev/sda1" = { label = "root", size = 100 }
      "xvdd"      = { label = "data", size = 300 }
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
        {
          backup = true
        }
      )
    }
    # Load balancer configuration for DIS
    lb_target_config = {
      endpoint             = "ndl-dis"
      port                 = 8080
      health_check_path    = "/BOE/CMC/"
      health_check_matcher = "200,302,301"
    }
  }
  # automation test instance only - do not use
  auto_config_dev = {
    instance_count = 0
    ami_name       = "delius_mis_windows_server_patch_2025-*"
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
        { backup      = false
          server-type = "MISDis"
        }
      )
    }
  }

  # new DFI instance config to differentiate from DIS
  dfi_config_dev = {
    instance_count = 1
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
  base_db_config_dev = {
    instance_type  = "m7i.large"
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

  # use slightly different config for each database
  dsd_db_config_dev = local.base_db_config_dev

  boe_db_config_dev = local.base_db_config_dev

  mis_db_config_dev = merge(local.base_db_config_dev, {
    ebs_volume_config = {
      data = {
        iops       = 5000
        total_size = 500
      }
      flash = {
        total_size = 500
      }
    }
  })

  dfi_report_bucket_config = {
    bucket_policy_enabled = true
  }

  fsx_config_dev = {
    storage_capacity     = 100
    throughtput_capacity = 16
  }

  lb_config = {
    bucket_policy_enabled = true
  }

  # DataSync configuration for syncing S3 bucket to FSX share
  # Default schedule: Lambda at 04:00 UTC, DataSync at 04:15 UTC
  # To override schedules, add schedule_expression and/or lambda_schedule_expression parameters:
  # Note: Always ensure Lambda runs 15+ minutes before DataSync for credential refresh
  datasync_config_dev = {
    source_s3_bucket_arn = "arn:aws:s3:::eu-west-2-delius-mis-dev-dfi-extracts" # differs per environment
    # schedule_expression = "cron(30 9 * * ? *)"        # Uncomment to run DataSync at 09:30 UTC (10:30 BST)
    # lambda_schedule_expression = "cron(15 9 * * ? *)"  # Uncomment to run Lambda at 09:15 UTC (10:15 BST)
    # fsx_domain = "delius-mis-dev.internal"            # Override FSX domain if needed
  }
}

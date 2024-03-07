# Terraform configuration data for environments in delius-mis development account

locals {
  environment_config_dev = {
    legacy_engineering_vpc_cidr = "10.161.98.0/25"
    legacy_counterpart_vpc_cidr = "10.162.32.0/20"
    legacy_ad_domain_name       = "delius-mis-dev.local"
    legacy_ad_ip_list           = ["10.162.36.235", "10.162.35.251"]
  }

  bastion_config_dev = {
    extra_user_data_content = "yum install -y openldap-clients"
  }

  bcs_config_dev = {
    instance_count = 1
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

  bps_config_dev = {
    instance_count = 1
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

  bws_config_dev = {
    instance_count = 1
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

  dis_config_dev = {
    instance_count = 1
    ami_name       = "delius_mis_windows_server_patch_2024-02-07T11-03-13.202Z"
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
}

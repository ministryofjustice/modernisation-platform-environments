# nomis-production environment settings
locals {
  nomis_production = {
    # ip ranges for external access to database instances
    database_external_access_cidr = [
      local.cidrs.noms_live,
      local.cidrs.noms_mgmt_live,
      local.cidrs.cloud_platform
    ]

    # Details of OMS Manager in FixNGo (only needs defining if databases in the environment are managed)
    database_oracle_manager = {
      oms_ip_address = "10.40.0.136"
      oms_hostname   = "oem"
    }
    # vars common across ec2 instances
    ec2_common = {
      public_key                = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDdCvr+81dRu1qxFi1LSWEybb/ztbzlbfjd3Hj1EOHcEQt6lo9Cr94SUXjjUvD6krNzm9QWs8TdVRNfDCjaZRmO6KFX8UUUwE0UB0p6LZPy2I8cYirGN8f2fwCrh8dZg6x8sxa7fXW5gMZal6Z0O10u0XM5ajXkQz2f4T4zCxff7MDEuqZV0OWhaiTWPT9eph4UZH5FWA8Lxzml6qIAwyHa6O5j7hQpvX4kiMjvg9F9C5Fxo6EBpCAjdRcXgsMmDHQjqLJO3b2wWPlm45yES7NaAwZCb6Yq0BRmDPv2/ZokVNE8tudtf+cNa2+aLB9WiBVnFXggIuFeelArNi5X9U4nLzvaDX3y7+TnY+QY5FcDugJDwHKcb/ah64WMpSiWjrFiyg6fF04jFfV6YKdsH//7E/DSZAkVsj+XKHt23SyWS6RKXag+IW3UIp3pttELNHbIO+7vUGZT8btqIBtN5iM6PLiYzfDFHDRmd/aO0a844ZFioFzabGo7MuyAU+NkfLHIBXazrrxd2s+HXnBtL80iur4Jm7Vut1QoPJmknCq9iBv+itE8RYM8oN74g5BVTPAsw5vr2c5fvXwVdu0XhwRnkSsfCppdntf2ObX51PxjxXcq63jCEYRdq0bBPyGWa8hKiMcwx4TIz3IW2xGmLK6PO+2LLpVg89Q7EicMAFHC3w=="
      patch_approval_delay_days = 7
      patch_day                 = "THU"
    }

    # cloud watch log groups
    log_groups = {
      session-manager-logs = {
        retention_days = 400
      }
      cwagent-var-log-messages = {
        retention_days = 90
      }
      cwagent-var-log-secure = {
        retention_days = 400
      }
      cwagent-nomis-autologoff = {
        retention_days = 400
      }
    }

    # Legacy database module, do not add any more entries here
    databases_legacy = {
      AUDIT = {
        always_on              = true
        ami_name               = "nomis_db_STIG-2022-04-26*"
        instance_type          = "r6i.2xlarge"
        asm_data_capacity      = 4000
        asm_flash_capacity     = 1000
        description            = "Copy of Production NOMIS Audit database in Azure PDPDL00038, replicating with PDPDL00038, a replacement for PDPDL00037."
        termination_protection = true
        oracle_sids            = ["PCNMAUD"]
        oracle_app_disk_size = {
          "/dev/sdb" = 100  # /u01
          "/dev/sdc" = 5120 # /u02
        }
        tags = {
          monitored = true
        }
      }
    }

    # Add database instances here. They will be created using ec2-database.tf
    databases = {
      # Naming
      # *-nomis-db-1: NOMIS, NDH, TRDATA
      # *-nomis-db-2: MIS, AUDIT
      # *-nomis-db-3: HA

      # NOTE: this is temporarily under prod account while we wait for network connectivity
      preprod-nomis-db-2 = {
        tags = {
          server-type = "nomis-db"
          description = "PreProduction NOMIS MIS and Audit database to replace Azure PPPDL00017"
          oracle-sids = "PPMIS PPCNMAUD"
          monitored   = false
          always-on   = true
        }
        ami_name  = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-03T12-51-25.032Z"
        ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
        instance = {
          instance_type           = "r6i.2xlarge"
          disable_api_termination = true
        }
        ebs_volumes = {
          "/dev/sdb" = { size = 100 }  # /u01
          "/dev/sdc" = { size = 5120 } # /u02 - reduce this to 1000 when we move into preprod subscription
        }
        ebs_volume_config = {
          data  = { total_size = 4000 }
          flash = { total_size = 1000 }
        }
      }

      prod-nomis-db-2 = {
        tags = {
          server-type = "nomis-db"
          description = "Production NOMIS MIS and Audit database to replace Azure PDPDL00036 and PDPDL00038"
          oracle-sids = "PCNMAUD"
          monitored   = false
          always-on   = true
        }
        ami_name  = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-07T12-48-08.562Z"
        ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
        instance = {
          instance_type           = "r6i.2xlarge"
          disable_api_termination = true
        }
        ebs_volumes = {
          "/dev/sdb" = { size = 100 }  # /u01
          "/dev/sdc" = { size = 1000 } # /u02
        }
        ebs_volume_config = {
          data  = { total_size = 4000 }
          flash = { total_size = 1000 }
        }
      }

      prod-nomis-db-3 = {
        tags = {
          server-type = "nomis-db"
          description = "Production NOMIS HA database to replace Azure PDPDL00062"
          monitored   = false
          always-on   = true
        }
        ami_name  = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-07T12-48-08.562Z"
        ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
        instance = {
          instance_type           = "r6i.2xlarge"
          disable_api_termination = true
        }
        ebs_volumes = {
          "/dev/sdb" = { size = 100 }  # /u01
          "/dev/sdc" = { size = 1000 } # /u02
        }
        ebs_volume_config = {
          data  = { total_size = 3000 }
          flash = { total_size = 500 }
        }
      }
    }

    # Add weblogic instances here.  They will be created using the weblogic module
    weblogics = {}
  }
}

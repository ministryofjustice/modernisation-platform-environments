# This file is for vars that vary between accounts.  Locals.tf conatins common vars.
locals {
  accounts = {
    test = {
      # ip ranges for external access to database instances
      database_external_access_cidr = {
        azure_noms_test      = "10.101.0.0/16"
        azure_noms_mgmt_test = "10.102.0.0/16"
        cloud_platform       = "172.20.0.0/16"
      },

      # vars common across ec2 instances
      ec2_common = {
        public_key                = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCv/RZr7NQwO1Ovjbaxs5X9jR1L4QU/WSOIH3qhCriTlzbdnPI5mA79ZWBZ25h5tA2eIu5FbX+DBwYgwARCnS6VL4KiLKq9j7Ys/gx2FE6rWlXEibpK/9dGLu35znDUyO0xiLIu/EPZFpWhn/2L1z82GiEjDaiY00NmxkHHKMaRCDrgCJ4tEhGPWGcPYoNAYmCkncQJjYojSJ0uaP6e85yx2nmE85YDE+QcDoN5HtHex84CCibh98nD2tMhEQ2Ss+g7/nSXw+/Z2RadDznpz0h/8CcgAGpTHJ35+aeWINquw0lWSJldCLfn3PXldcDzFleqoop9jRGn2hB9eOUz2iEC7MXoLPFcen/lzQD+xfwvaq1+4YU7BbiyTtY/lcw0xcE01QBA+nUiHPJMBewr2TmZRHNy1fvg8ZRKLrOcEMz8iPKVtquftl1DZZCO8Xccr3BVpfoXIl5LuEWPqnMABAvgtkHMaIkTqKMgaKVEC9/KTqRn/K2zzGljUJkzcgO95bNksjDRXtbfQ0AD7CLa47xPOLPh4dC2WDindKh3YALa74EBOyEtJWvLt6fRLPhWmOaZkCrjC3TI+onKiPo0nXrN7Uyg2Q6Atiauw6fqz63cRXkzU/e7LVoxT42qaaaGMytgZJXF3Wk4hp88IqqnDXFavLUElsJEgOTWiNTk2N92/w=="
        patch_approval_delay_days = 3
        patch_day                 = "TUE"
      },
      # cloud watch log groups
      log_groups = {
        session-manager-logs = {
          retention_days = 90
        },
        cwagent-var-log-messages = {
          retention_days = 30
        },
        cwagent-var-log-secure = {
          retention_days = 90
        },
        cwagent-nomis-autologoff = {
          retention_days = 90
        }
      },
      # Add database instances here.  They will be created using the database module
      databases = {
        CNOMT1 = {
          always_on          = false
          ami_name           = "nomis_db_STIG_CNOMT1-2022-04-21*"
          asm_data_capacity  = 100
          asm_flash_capacity = 2
          description        = "Test NOMIS T1 database with a dataset of T1PDL0009 (note: only NOMIS db, NDH db is not included."
          tags = {
            monitored = false
          }
        },
        CNOMT1_COPY = {
          always_on          = false
          ami_name           = "nomis_db_STIG_CNOMT1-2022-04-21*"
          asm_data_capacity  = 100
          asm_flash_capacity = 2
          description        = "Test NOMIS T1 database with a dataset of T1PDL0009 (note: only NOMIS db, NDH db is not included. Used for oracle secure web install testing."
          oracle_sids        = ["CNOMT1"]
          tags = {
            monitored = true
          }
        },
        CNAUDT1 = {
          always_on              = true
          ami_name               = "nomis_db-2022-03-03*"
          asm_data_capacity      = 200
          asm_flash_capacity     = 2
          description            = "Copy of Test NOMIS Audit database in Azure T1PDL0010, replicating with T1PDL0010."
          termination_protection = true
          oracle_sids            = ["MIST1", "CNMAUDT1"]
          tags = {
            monitored = false
          }
        }
      },
      # Add weblogic instances here.  They will be created using the weblogic module
      weblogics = {
        CNOMT1 = {
          ami_name     = "nomis_Weblogic_2022*"
          asg_max_size = 1
        }
      }
      backup = {
        key   = "backup"
        value = true
        rules = [{
          name                     = "daily_snapshot"
          schedule                 = "cron(10 10 ? * MON-SAT *)"
          start_window             = 60
          completion_window        = 180
          delete_after             = 7
          enable_continuous_backup = true
          },
          {
            name                     = "weekly_snapshot"
            schedule                 = "cron(40 19 ? * 1 *)"
            start_window             = 60
            completion_window        = 180
            delete_after             = 30
            enable_continuous_backup = false
          },
          {
            name                     = "monthly_snapshot"
            schedule                 = "cron(0 5 1 * ? *)"
            start_window             = 60
            completion_window        = 180
            delete_after             = 60
            enable_continuous_backup = false
          }
        ]
      }
    },
    production = {
      # ip ranges for external access to database instances
      database_external_access_cidr = {
        azure_noms_live      = "10.40.0.0/18"
        cloud_platform       = "172.20.0.0/16"
        azure_noms_mgmt_live = "10.40.128.0/20"
      },

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
      },
      # cloud watch log groups
      log_groups = {
        session-manager-logs = {
          retention_days = 400
        },
        cwagent-var-log-messages = {
          retention_days = 90
        },
        cwagent-var-log-secure = {
          retention_days = 400
        },
        cwagent-nomis-autologoff = {
          retention_days = 400
        }
      },
      # Add database instances here.  They will be created using the database module
      databases = {
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
            backup    = true
          }
        },
        NOMIS = {
          always_on              = true
          ami_name               = "nomis_db_STIG-2022-04-26*"
          instance_type          = "r6i.4xlarge"
          asm_data_capacity      = 4000
          asm_flash_capacity     = 1000
          description            = "Copy of Production NOMIS CNOM database in Azure PDPDL00035, replicating with PDPDL00035, a replacement for PDPDL10036."
          termination_protection = true
          oracle_sids            = ["PCNOM", "PMISS1"]
          oracle_app_disk_size = {
            "/dev/sdb" = 100 # /u01
            "/dev/sdc" = 512 # /u02
          }
          tags = {
            monitored = false //not yet live
            backup    = false
          }
        }
      },
      # Add weblogic instances here.  They will be created using the weblogic module
      weblogics = {}
    }
  }
}

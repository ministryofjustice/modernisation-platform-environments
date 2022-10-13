# nomis-development environment settings
locals {
  nomis_development = {
    # ip ranges for external access to database instances
    database_external_access_cidr = [
      local.cidrs.noms_test,
      local.cidrs.noms_mgmt,
      local.cidrs.cloud_platform
    ]

    # vars common across ec2 instances
    ec2_common = {
      public_key                = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCv/RZr7NQwO1Ovjbaxs5X9jR1L4QU/WSOIH3qhCriTlzbdnPI5mA79ZWBZ25h5tA2eIu5FbX+DBwYgwARCnS6VL4KiLKq9j7Ys/gx2FE6rWlXEibpK/9dGLu35znDUyO0xiLIu/EPZFpWhn/2L1z82GiEjDaiY00NmxkHHKMaRCDrgCJ4tEhGPWGcPYoNAYmCkncQJjYojSJ0uaP6e85yx2nmE85YDE+QcDoN5HtHex84CCibh98nD2tMhEQ2Ss+g7/nSXw+/Z2RadDznpz0h/8CcgAGpTHJ35+aeWINquw0lWSJldCLfn3PXldcDzFleqoop9jRGn2hB9eOUz2iEC7MXoLPFcen/lzQD+xfwvaq1+4YU7BbiyTtY/lcw0xcE01QBA+nUiHPJMBewr2TmZRHNy1fvg8ZRKLrOcEMz8iPKVtquftl1DZZCO8Xccr3BVpfoXIl5LuEWPqnMABAvgtkHMaIkTqKMgaKVEC9/KTqRn/K2zzGljUJkzcgO95bNksjDRXtbfQ0AD7CLa47xPOLPh4dC2WDindKh3YALa74EBOyEtJWvLt6fRLPhWmOaZkCrjC3TI+onKiPo0nXrN7Uyg2Q6Atiauw6fqz63cRXkzU/e7LVoxT42qaaaGMytgZJXF3Wk4hp88IqqnDXFavLUElsJEgOTWiNTk2N92/w=="
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    # cloud watch log groups
    log_groups = {
      session-manager-logs = {
        retention_days = 90
      }
      cwagent-var-log-messages = {
        retention_days = 30
      }
      cwagent-var-log-secure = {
        retention_days = 90
      }
      cwagent-nomis-autologoff = {
        retention_days = 90
      }
    }

    databases_legacy = {}
    databases = {
      # Naming
      # *-nomis-db-1: NOMIS, NDH, TRDATA
      # *-nomis-db-2: MIS, AUDIT
      # *-nomis-db-3: HA
      test-nomis-db-2 = {
        tags = {
          server-type = "nomis-db"
          description = "T1 NOMIS test database to replace Azure T1PDL0009"
          oracle-sids = "CNOMT1"
          monitored   = false
          always-on   = true
        }
        ami_name = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-07T12-48-08.562Z"
        instance = {
          disable_api_termination = true
        }
        ebs_volume_config = {
          data  = { total_size = 200 }
          flash = { total_size = 2 }
        }
        # branch            = "nomis/DSOS-1426/load-CNOMT1-data-role"
        # s3-db-restore-dir = "CNOMT1_20211214"
      }

    }
    weblogics          = {}
    base_instances_asg = {}
    test_instances_asg = {}
  }
}


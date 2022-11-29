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
    databases_legacy = {}

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
        }
        ami_name  = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-03T12-51-25.032Z"
        ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
        instance = {
          instance_type             = "r6i.2xlarge"
          disable_api_termination   = true
          metadata_endpoint_enabled = "enabled"
        }
        ebs_volumes = {
          "/dev/sdb" = { # /u01
            size = 100
            type = "gp3"
          }
          "/dev/sdc" = { # /u02
            type = "gp3"
            size = 5120 # reduce this to 1000 when we move into preprod subscription
          }
        }
        ebs_volume_config = {
          app = {
            type = "gp3"
          }
          data = {
            type       = "gp3"
            total_size = 4000
          }
          flash = {
            type       = "gp3"
            total_size = 1000
          }
          swap = {
            type = "gp3"
          }
        }
      }

      prod-nomis-db-2 = {
        tags = {
          server-type              = "nomis-db"
          description              = "Production NOMIS MIS and Audit database to replace Azure PDPDL00036 and PDPDL00038"
          oracle-sids              = "PCNMAUD"
          monitored                = false
          fixngo-connection-target = "10.40.0.136"
        }
        ami_name  = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-07T12-48-08.562Z"
        ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
        instance = {
          instance_type             = "r6i.2xlarge"
          disable_api_termination   = true
          metadata_endpoint_enabled = "enabled"
        }
        ebs_volumes = {
          "/dev/sdb" = { # /u01
            size = 100
            type = "gp3"
          }
          "/dev/sdc" = { # /u02
            size = 3000
            type = "gp3"
            iops = 9000
          }
        }
        ebs_volume_config = {
          app = {
            type = "gp3"
          }
          data = {
            type       = "gp3"
            total_size = 4000
          }
          flash = {
            type       = "gp3"
            total_size = 1000
          }
          swap = {
            type = "gp3"
          }
        }
      }

      prod-nomis-db-3 = {
        tags = {
          server-type = "nomis-db"
          description = "Production NOMIS HA database to replace Azure PDPDL00062"
          monitored   = false
        }
        ami_name  = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-07T12-48-08.562Z"
        ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
        instance = {
          instance_type             = "r6i.2xlarge"
          disable_api_termination   = true
          metadata_endpoint_enabled = "enabled"
        }
        ebs_volumes = {
          "/dev/sdb" = { # /u01
            size = 100
            type = "gp3"
          }
          "/dev/sdc" = { # /u02
            size = 1000
            type = "gp3"
          }
        }
        ebs_volume_config = {
          app = {
            type = "gp3"
          }
          data = {
            type       = "gp3"
            total_size = 3000
          }
          flash = {
            type       = "gp3"
            total_size = 500
          }
          swap = {
            type = "gp3"
          }
        }
      }
    }

    # Add weblogic instances here.  They will be created using the weblogic module
    weblogics       = {}
    ec2_jumpservers = {}
  }
}

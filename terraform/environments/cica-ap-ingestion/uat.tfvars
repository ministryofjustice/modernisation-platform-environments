data_eng_role = "arn:aws:iam::189157455002:role/data-engineering-infrastructure"
data_prod_role = "arn:aws:iam::593291632749:role/data-engineering-infrastructure"

vpc = {
  cidr_block = "172.27.0.0/16"
  private_subnets = [
    {
      availability_zone = "eu-west-1a"
      cidr_block = "172.24.0.0/20"
      enable_test_instance = false
    },
    {
      availability_zone = "eu-west-1b"
      cidr_block = "172.24.16.0/20"
    },
    {
      availability_zone = "eu-west-1c"
      cidr_block = "172.24.32.0/20"
      enable_test_instance = true
    }
  ]
  protect = false
  s3_endpoint = {
    bucket_name = " mojap-land-dev"
  }
  transit_gateway  = [
    {
      name = "moj"
      id = "tgw-0e7b982ea47c28fba"
      routes = [
        {
          cidr_block = "172.20.0.0/16"
          rule_number = 105
          name = "cloud-platform"
        },
        {
          cidr_block = "10.161.4.0/22"
          rule_number = 110
          name = "delius-sandpit"
        },
        {
          cidr_block = "10.101.0.0/16"
          rule_number = 115
          name = "noms-test"
        }
      ]
    }
  ]
}

landing_bucket  = "mojap-land-dev"
fail_bucket     = "mojap-fail-dev"
metadata_bucket = "mojap-metadata-dev"
raw_hist_bucket = "mojap-raw-hist-dev"

databases = {
  delius = {
    metadata_folder = "delius_sandpit"  # this is duplicated!!
    source_database = "delius"  # this is duplicated!!
    target_database_name   = "delius_sandbox_raw_hist"
    database_description   = ""
    source_base_folder     = "hmpps/delius/DELIUS_ANALYTICS_PLATFORM"

    lambda = {
      fail_bucket     = "mojap-fail-dev"
      metadata_bucket = "mojap-metadata-dev"
      metadata_path   = "delius"
      raw_hist_bucket = "mojap-raw-hist-dev"
    }
    table_mappings = {
      metadata_folder = "delius/delius_sandpit"
      metadata_file = "delius/delius_sandpit.json"
      schema   = "DELIUS_ANALYTICS_PLATFORM"
    }
    replication_instance = {
      allocated_storage          = 50
      apply_immediately          = true
      engine_version             = "3.5.1"
      instance_number            = 1
      multi_az                   = false
      replication_instance_class = "dms.t3.micro"
      replication_tasks = [
        {
          migration_type = "cdc"
          task_number = 0
          start_replication_task = true
          replication_task_settings = {
            ChangeProcessingTuning = {
              RecoveryTimeout = -1
            }
          }
        },
        {
          migration_type = "full-load"
          task_number = 1
          start_replication_task = false
          replication_task_settings = {
            ChangeProcessingTuning = {
              RecoveryTimeout = -1
            }
          }
        }
      ]
    }
    security_group = {
      ingress = {
        cidr_blocks = [
          "10.161.4.0/22"
        ]
      }
    }
    source_endpoint = {
      database_name = "sanndas2"
      engine_name   = "oracle"
      port          = 1521
      extra_connection_attributes = {
        additionalArchivedLogDestId = 3
        archivedLogDestId           = 1
        asm_server = "delius-db-3.sandpit.delius-core.probation.hmpps.dsd.io/+ASM"
        asm_user = "delius_analytics_platform"
        parallelASMReadThreads = 8
        readAheadBlocks = 200000
        useLogminerReader           = "N"
        useBfile                    = "Y"
        addSupplementalLogging      = "N"
        allowSelectNestedTables     = true
      }
      server_name = "delius-db-3.sandpit.delius-core.probation.hmpps.dsd.io"
    }
    target_endpoint = {
      engine_name = "s3"
      s3_settings = {
        bucket_folder = "hmpps/delius"
        bucket_name   = "mojap-land-dev"
      }
    }
  }
  oasys = {
    metadata_folder = "oasys_t2"  # this is duplicated!!
    source_database = "oasys"  # this is duplicated!!
    target_database_name   = "oasys_dev_raw_hist"
    database_description   = ""
    source_base_folder     = "hmpps/oasys/EOR"

    lambda = {
      fail_bucket     = "mojap-fail-dev"
      metadata_bucket = "mojap-metadata-dev"
      metadata_path   = "oasys"
      raw_hist_bucket = "mojap-raw-hist-dev"
    }
    table_mappings = {
      metadata_folder = "oasys/oasys_t2"
      metadata_file = "oasys/oasys_t2.json"
      schema   = "public"
    }
    replication_instance = {
      allocated_storage          = 50
      apply_immediately          = true
      engine_version             = "3.5.1"
      instance_number            = 0
      multi_az                   = false
      replication_instance_class = "dms.t3.micro"
      replication_tasks = [
        {
          migration_type = "cdc"
          task_number = 0
          start_replication_task = true
          replication_task_settings = {
            ChangeProcessingTuning = {
              RecoveryTimeout = -1
            }
          }
        },
        {
          migration_type = "full-load"
          task_number = 1
          start_replication_task = false
          replication_task_settings = {
            ChangeProcessingTuning = {
              RecoveryTimeout = -1
            }
          }
        },
        # i think we should probably just kill the full-load and cdc tasks (we never use them!)
        {
          migration_type = "full-load-and-cdc"
          task_number = 2
          start_replication_task = false
          replication_task_settings = {
            FullLoadSettings = {
              TargetTablePrepMode = "DO_NOTHING"
            },
            TargetMetadata = {
              LobMaxSize = 64
            }
          }
        }
      ]
    }
    security_group = {
      ingress = {
        cidr_blocks = [
          "10.101.0.0/16"
        ]
      }
    }
    source_endpoint = {
      database_name = "OASPROD"
      engine_name   = "oracle"
      server_name   = "10.101.36.132"
      port          = 5432
      # i dont think these are currently used - may need some time playing in dev to get stuff working...
      extra_connection_attributes = {
        additionalArchivedLogDestId = 2
        archivedLogDestId = 1
        asm_server = "10.101.36.132/+ASM"
        asm_user = "aws"
        parallelASMReadThreads = 8
        readAheadBlocks = 200000
        useLogminerReader = "N"
        useBfile = "Y"
        addSupplementalLogging = "N"
        allowSelectNestedTables = true
      }
    }
    target_endpoint = {
      engine_name = "s3"
      s3_settings = {
        bucket_folder = "hmpps/oasys"
        bucket_name   = "mojap-land-dev"
      }
    }
  }
}
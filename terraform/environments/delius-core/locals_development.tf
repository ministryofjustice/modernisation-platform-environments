# Terraform configuration data for environments in delius-core development account

# Sample data
# tags demonstrate inheritance due to merges in the module
locals {
  environment_config_dev = {
    migration_environment_private_cidr     = ["10.162.32.0/22", "10.162.36.0/22", "10.162.40.0/22"]
    migration_environment_db_cidr          = ["10.162.44.0/24", "10.162.45.0/24", "10.162.46.0/25"]
    migration_environment_full_name        = "dmd-mis-dev"
    migration_environment_abbreviated_name = "dmd"
    migration_environment_short_name       = "mis-dev"
    legacy_engineering_vpc_cidr            = "10.161.98.0/25"
    ec2_user_ssh_key                       = file("${path.module}/files/.ssh/${terraform.workspace}/ec2-user.pub")
    homepage_path                          = "/"
  }

  ldap_config_dev = {
    name                        = "ldap"
    encrypted                   = true
    migration_source_account_id = local.application_data.accounts[local.environment].migration_source_account_id
    migration_lambda_role       = "ldap-data-migration-lambda-role"
    efs_throughput_mode         = "bursting"
    efs_provisioned_throughput  = null
    efs_backup_schedule         = "cron(0 19 * * ? *)",
    efs_backup_retention_period = "30"
    port                        = 389
  }

  db_config_dev = {
    instance_type  = "r6i.xlarge"
    ami_name_regex = "^delius_core_ol_8_5_oracle_db_19c_patch_2024-01-31T16-06-00.575Z"
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
        total_size = 500
      }
      flash = {
        iops       = 3000
        throughput = 125
        type       = "gp3"
        total_size = 500
      }
    }
    ansible_user_data_config = {
      branch               = "main"
      ansible_repo         = "modernisation-platform-configuration-management"
      ansible_repo_basedir = "ansible"
      ansible_args         = "oracle_19c_install"
    }
  }

  delius_microservices_configs_dev = {
    gdpr_ui = {
      image_tag      = "REPLACE"
      container_port = 80
    }

    gdpr_api = {
      image_tag             = "REPLACE"
      container_port        = 8080
      create_rds            = true
      rds_engine            = "postgres"
      rds_engine_version    = "15"
      rds_instance_class    = "db.t3.small"
      rds_allocated_storage = 30
      rds_username          = "gdpr"
      rds_port              = 5432
      rds_license_model     = "postgresql-license"
    }

    merge_api = {
      container_port        = 8080
      image_tag             = "REPLACE"
      create_rds            = true
      rds_engine            = "postgres"
      rds_engine_version    = "15"
      rds_instance_class    = "db.t3.small"
      rds_allocated_storage = 30
      rds_username          = "dbadmin"
      rds_port              = 5432
      rds_license_model     = "postgresql-license"
      rds_deletion_protection = false
      rds_skip_final_snapshot = true
      snapshot_identifier = "rds-migration-1145"
    }

    merge_ui = {
      image_tag      = "REPLACE"
      container_port = 80
    }

    weblogic = {
      image_tag        = "5.7.6"
      container_port   = 8080
      container_memory = 4096
      container_cpu    = 2048
    }

    weblogic_eis = {
      image_tag        = "5.7.6"
      container_port   = 8080
      container_memory = 2048
      container_cpu    = 1024
    }

    user_management = {
      image_tag        = "5.7.6"
      container_port   = 8080
      container_memory = 4096
      container_cpu    = 1024
    }

    pwm = {
      image_tag      = "8250538047-1"
      container_port = 8080
    }

    pdf_creation = {
      image_tag      = "5.7.6"
      container_port = 80
    }

    newtech = {
      image_tag      = "5.7.6"
      container_port = 80
    }
  }

  bastion_config_dev = {
    business_unit           = local.vpc_name
    subnet_set              = local.subnet_set
    environment             = local.environment
    extra_user_data_content = "yum install -y openldap-clients"
  }
}

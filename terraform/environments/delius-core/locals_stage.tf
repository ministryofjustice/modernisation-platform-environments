# Terraform configuration data for environments in delius-core test account

# Sample data
# tags demonstrate inheritance due to merges in the module
locals {
  environment_config_stage = {
    migration_environment_private_cidr     = ["10.160.32.0/22", "10.160.36.0/22", "10.160.40.0/22"]
    migration_environment_vpc_cidr         = "10.160.32.0/20"
    migration_environment_db_cidr          = ["10.160.44.0/24", "10.160.45.0/24", "10.160.46.0/25"]
    migration_environment_full_name        = "del-stage"
    migration_environment_abbreviated_name = "del"
    migration_environment_short_name       = "stage"
    legacy_engineering_vpc_cidr            = "10.160.98.0/25"
    ec2_user_ssh_key                       = file("${path.module}/files/.ssh/stage/ec2-user.pub")
    homepage_path                          = "/NDelius-war/delius/JSP/auth/login.xhtml"
    has_mis_environment                    = true
  }

  ldap_config_stage = {
    name                        = "ldap"
    encrypted                   = true
    migration_source_account_id = "205048117103"
    migration_lambda_role       = "ldap-data-migration-lambda-role"
    efs_throughput_mode         = "elastic"
    efs_provisioned_throughput  = null
    efs_backup_schedule         = "cron(0 19 * * ? *)",
    efs_backup_retention_period = "30"
    port                        = 389
    tls_port                    = 636
    desired_count               = 1
    log_retention               = 0
  }


  db_config_stage = {
    instance_type  = "r7i.2xlarge"
    ami_name_regex = "^delius_core_ol_8_5_oracle_db_19c_patch_2024-06-04T11-24-58.162Z"

    primary_instance_count = 1
    standby_count          = 0

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
        throughput = 400
        type       = "gp3"
        total_size = 10000
      }
      flash = {
        iops       = 3000
        throughput = 400
        type       = "gp3"
        total_size = 1000
      }
    }
    ansible_user_data_config = {
      branch               = "main"
      ansible_repo         = "modernisation-platform-configuration-management"
      ansible_repo_basedir = "ansible"
      ansible_args         = "oracle_19c_install"
    }
    database_name = "change_me"
    database_port = local.db_port
  }

  delius_microservices_configs_stage = {
    weblogic = {
      image_tag        = "6.2.0.3"
      container_port   = 8080
      container_memory = 4096
      container_cpu    = 2048
    }

    weblogic_eis = {
      image_tag        = "6.2.0.3"
      container_port   = 8080
      container_memory = 2048
      container_cpu    = 1024
    }

    pwm = {
      image_tag        = "8250538047-1"
      container_port   = 8080
      container_cpu    = 512
      container_memory = 1024
    }

    ldap = {
      image_tag                 = "6.2.3-latest"
      container_port            = 389
      slapd_log_level           = "conns,config,stats,stats2"
      container_cpu             = 8192
      container_memory          = 16384
      health_check_start_period = 480
    }

    sfs = {
      container_cpu    = 2048
      container_memory = 4096
    }
  }

  bastion_config_stage = {
    business_unit           = local.vpc_name
    subnet_set              = local.subnet_set
    environment             = local.environment
    extra_user_data_content = "yum install -y openldap-clients"
  }

  dms_config_stage = {
    deploy_dms                 = false
    replication_instance_class = "dms.t3.medium"
    engine_version             = "3.5.4"

    # This map overlaps with the Ansible database configuration in delius-environment-configuration-management/ansible/group_vars
    # Please ensure any changes made here are consistent with Ansible variables.
    audit_source_endpoint = {
      read_host     = "primarydb"
      read_database = "STGNDA"
    }
    audit_target_endpoint = {
      write_environment = "stage" # Until production exists set dummy replication target
      write_database    = "NONE"  # Remove this dummy attribute once production target exists
    }
    user_source_endpoint = { # Set this map to {} once production exists
      read_host     = "primarydb"
      read_database = "NONE"
    }
    user_target_endpoint = {
      write_database = "STGNDA"
    }
    # Auditing from the Stage environment is considered production data
    is-production = true
  }
}

# Terraform configuration data for environments in delius-core test account

# Sample data
# tags demonstrate inheritance due to merges in the module
locals {

  environment_config_test = {
    migration_environment_private_cidr     = ["10.162.8.0/22", "10.162.4.0/22", "10.162.0.0/22"]
    migration_environment_vpc_cidr         = "10.162.0.0/20"
    migration_environment_db_cidr          = ["10.162.14.0/25", "10.162.13.0/24", "10.162.12.0/24"]
    migration_environment_full_name        = "del-test"
    migration_environment_abbreviated_name = "del"
    migration_environment_short_name       = "test"
    legacy_engineering_vpc_cidr            = "10.161.98.0/25"
    ec2_user_ssh_key                       = file("${path.module}/files/.ssh/test/ec2-user.pub")
    homepage_path                          = "/NDelius-war/delius/JSP/auth/login.xhtml"
    has_mis_environment                    = false
  }

  ldap_config_test = {
    name                        = "ldap"
    encrypted                   = true
    migration_source_account_id = "728765553488"
    migration_lambda_role       = "ldap-data-migration-lambda-role"
    efs_throughput_mode         = "bursting"
    efs_provisioned_throughput  = null
    efs_backup_schedule         = "cron(0 19 * * ? *)",
    efs_backup_retention_period = "30"
    port                        = 389
    tls_port                    = 636
    desired_count               = 1
    log_retention               = 7
  }


  db_config_test = {
    instance_type  = "r7i.xlarge"
    ami_name_regex = "^delius_core_ol_8_5_oracle_db_19c_patch_2024-01-31T16-06-00.575Z"
    instance_policies = {
      "business_unit_kms_key_access" = aws_iam_policy.business_unit_kms_key_access
    }

    primary_instance_count = 1
    standby_count          = 0
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
        total_size = 1000
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
    database_name = "change_me"
    database_port = local.db_port
  }

  delius_microservices_configs_test = {
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
      container_cpu    = 1024
      container_memory = 2048
    }

    ldap = {
      image_tag                 = "6.2.4-latest"
      container_port            = 389
      slapd_log_level           = "conns,config,stats,stats2"
      container_cpu             = 2048
      container_memory          = 4096
      health_check_start_period = 120
    }

    sfs = {
      container_cpu    = 2048
      container_memory = 4096
    }
  }

  bastion_config_test = {
    business_unit           = local.vpc_name
    subnet_set              = local.subnet_set
    environment             = local.environment
    extra_user_data_content = "yum install -y openldap-clients"
  }

  dms_config_test = {
    deploy_dms                 = true
    replication_instance_class = "dms.t3.medium"
    engine_version             = "3.5.4"
    # This map overlaps with the Ansible database configuration in delius-environment-configuration-management/ansible/group_vars
    # Please ensure any changes made here are consistent with Ansible variables.
    audit_source_endpoint = {}
    audit_target_endpoint = {
      write_database = "TSTNDA"
    }
    user_source_endpoint = {
      read_host     = "primarydb"
      read_database = "TSTNDA"
    }
    user_target_endpoint = {}
    is-production        = false
    # Times must be specified in UTC
    disable_latency_alarms = {
      start_time      = "19:59"
      end_time        = "06:45"
      disable_weekend = true
    }
  }
}

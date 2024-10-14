# Terraform configuration data for environments in delius-core development account

# Sample data
# tags demonstrate inheritance due to merges in the module
locals {

  environment_config_dev = {
    migration_environment_private_cidr     = ["10.162.32.0/22", "10.162.36.0/22", "10.162.40.0/22"]
    migration_environment_vpc_cidr         = "10.162.32.0/20"
    migration_environment_db_cidr          = ["10.162.44.0/24", "10.162.45.0/24", "10.162.46.0/25"]
    migration_environment_full_name        = "dmd-mis-dev"
    migration_environment_abbreviated_name = "dmd"
    migration_environment_short_name       = "mis-dev"
    legacy_engineering_vpc_cidr            = "10.161.98.0/25"
    ec2_user_ssh_key                       = file("${path.module}/files/.ssh/dev/ec2-user.pub")
    homepage_path                          = "/"
    has_mis_environment                    = true
  }

  ldap_config_dev = {
    name                        = "ldap"
    encrypted                   = true
    migration_source_account_id = "479759138745"
    migration_lambda_role       = "ldap-data-migration-lambda-role"
    efs_throughput_mode         = "bursting"
    efs_provisioned_throughput  = null
    efs_backup_schedule         = "cron(0 19 * * ? *)",
    efs_backup_retention_period = "30"
    port                        = 389
    tls_port                    = 636
    desired_count               = 1
  }

  db_config_dev = {
    instance_type  = "m7i.large"
    ami_name_regex = "^delius_core_ol_8_5_oracle_db_19c_patch_2024-01-31T16-06-00.575Z"

    instance_policies = {
      "business_unit_kms_key_access" = aws_iam_policy.business_unit_kms_key_access
    }
    primary_instance_count = 1
    standby_count          = 2
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

    pwm = {
      image_tag        = "8250538047-1"
      container_port   = 8080
      container_cpu    = 512
      container_memory = 1024
    }

    ldap = {
      image_tag        = "6.0.3-latest"
      container_port   = 389
      slapd_log_level  = "stats"
      container_cpu    = 512
      container_memory = 1024
    }

    pdf_creation = {
      image_tag      = "2021-06-24.995.8c1da2c"
      container_port = 8080
    }

    newtech = {
      image_tag      = "2024-05-28.10054.9e25657"
      container_port = 80
    }
  }

  bastion_config_dev = {
    business_unit           = local.vpc_name
    subnet_set              = local.subnet_set
    environment             = local.environment
    extra_user_data_content = "yum install -y openldap-clients"
  }

  dms_config_dev = {
    deploy_dms                 = true
    replication_instance_class = "dms.t3.small"
    engine_version             = "3.5.2"
    # This map overlaps with the Ansible database configuration in delius-environment-configuration-management/ansible/group_vars
    # Please ensure any changes made here are consistent with Ansible variables.
    audit_source_endpoint = {
      read_host     = "standbydb2"
      read_database = "DMDNDAS2"
    }
    audit_target_endpoint = {
      write_environment = "test"
    }
    user_source_endpoint = {}
    user_target_endpoint = {
      write_database = "DMDNDA"
    }
    is-production = local.is-production
  }
}

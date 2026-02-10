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

    weblogic_params = {
      API_CLIENT_ID                     = "delius-ui-client"
      AWS_REGION                        = "eu-west-2"
      BREACH_NOTICE_API_URL             = "https://breach-notice-api-test.hmpps.service.justice.gov.uk"
      BREACH_NOTICE_UI_URL_FORMAT       = "https://breach-notice-test.hmpps.service.justice.gov.uk/breach-notice/%s"
      COOKIE_SECURE                     = "true"
      # DELIUS_API_URL                    = "" # No longer needed
      DMS_HOST                          = "https://hmpps-delius-alfresco-test.apps.live.cloud-platform.service.justice.gov.uk"
      DMS_OFFICE_URI_HOST               = "https://hmpps-delius-alfresco-test.apps.live.cloud-platform.service.justice.gov.uk"
      DMS_OFFICE_URI_PORT               = "443"
      DMS_PORT                          = "443"
      DMS_PROTOCOL                      = "https"
      EIS_USER_CONTEXT                  = "cn=EISUsers,ou=Users,dc=moj,dc=com"
      ELASTICSEARCH_URL                 = "https://probation-search-test.hmpps.service.justice.gov.uk/delius"
      GDPR_URL                          = "/gdpr/ui/homepage" # GDPR not deployed to CP yet, <URL>/gdpr/ui/homepage
      JDBC_CONNECTION_POOL_MAX_CAPACITY = "100"
      JDBC_CONNECTION_POOL_MIN_CAPACITY = "50"
      JDBC_URL                          = ""
      JDBC_USERNAME                     = "delius_pool"
      LDAP_HOST                         = "https://ldap.test.delius-core.hmpps-test.modernisation-platform.service.justice.gov.uk"
      LDAP_PRINCIPAL                    = "cn=admin,dc=moj,dc=com"
      LOG_LEVEL_NDELIUS                 = "DEBUG"
      MERGE_API_URL                     = "https://delius-merge-api-test.hmpps.service.justice.gov.uk"
      MERGE_OAUTH_URL                   = "https://delius-user-management-test.hmpps.service.justice.gov.uk/umt/oauth/"
      MERGE_URL                         = "https://delius-merge-ui-test.hmpps.service.justice.gov.uk"
      NDELIUS_CLIENT_ID                 = "migrations_client_id"
      OAUTH_CALLBACK_URL                = "https://ndelius.test.delius-core.hmpps-test.modernisation-platform.service.justice.gov.uk/NDelius-war/delius/JSP/auth/token.jsp"
      OAUTH_CLIENT_ID                   = "delius-ui"
      OAUTH_DEFAULT_SCOPE               = "delius"
      OAUTH_LOGIN_ENABLED               = "false"
      OAUTH_LOGIN_NAME                  = ""
      OAUTH_TOKEN_VERIFICATION_URL      = "https://token-verification-api-test.prison.service.justice.gov.uk/token/verify"
      OAUTH_URL                         = "https://sign-in-test.hmpps.service.justice.gov.uk/auth"
      OFFENDER_SEARCH_API_URL           = "https://probation-offender-search-test.hmpps.service.justice.gov.uk"
      PASSWORD_RESET_URL                = "https://pwm.test.delius-core.hmpps-test.modernisation-platform.service.justice.gov.uk/public/forgottenpassword"
      PDFCREATION_TEMPLATES             = "shortFormatPreSentenceReport|paroleParom1Report|oralReport"
      PDFCREATION_URL                   = "https://ndelius-new-tech-pdf-generator-test.hmpps.service.justice.gov.uk/newTech"
      PREPARE_CASE_FOR_SENTENCE_URL     = "https://prepare-a-case-test.apps.live-1.cloud-platform.service.justice.gov.uk"
      PSR_SERVICE_URL                   = "https://pre-sentence-service-test.hmpps.service.justice.gov.uk"
      TRAINING_MODE_APP_NAME            = "National Delius - TEST USE ONLY"
      TZ                                = "Europe/London"
      USERMANAGEMENT_URL                = "https://delius-user-management-test.hmpps.service.justice.gov.uk/umt/"
      USER_CONTEXT                      = "ou=Users,dc=moj,dc=com"
      USER_MEM_ARGS                     = "-XX:MaxRAMPercentage=90.0"
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
      image_tag        = "6.2.4-latest"
      container_port   = 389
      slapd_log_level  = "conns,config,stats,stats2"
      container_cpu    = 2048
      container_memory = 4096
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

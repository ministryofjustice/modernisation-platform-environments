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
    homepage_path                          = "/NDelius-war/delius/JSP/auth/login.xhtml"
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
    log_retention               = 7
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
    database_name = "DMDNDA"
    database_port = local.db_port
  }

  delius_microservices_configs_dev = {
    weblogic = {
      image_tag                = "6.5.15"
      container_port           = 8080
      container_memory         = 4096
      container_cpu            = 2048
      task_definition_revision = 14
    }

    weblogic_params = {
      API_CLIENT_ID                     = "delius-ui-client"
      AWS_REGION                        = "eu-west-2"
      BREACH_NOTICE_API_URL             = "https://breach-notice-api-dev.hmpps.service.justice.gov.uk"
      BREACH_NOTICE_UI_URL_FORMAT       = "https://breach-notice-dev.hmpps.service.justice.gov.uk/breach-notice/%s"
      COOKIE_SECURE                     = "true"
      # DELIUS_API_URL                    = "" # No longer needed
      DMS_HOST                          = "https://hmpps-delius-alfresco-dev.apps.live.cloud-platform.service.justice.gov.uk"
      DMS_OFFICE_URI_HOST               = "https://hmpps-delius-alfresco-dev.apps.live.cloud-platform.service.justice.gov.uk"
      DMS_OFFICE_URI_PORT               = "443"
      DMS_PORT                          = "443"
      DMS_PROTOCOL                      = "https"
      EIS_USER_CONTEXT                  = "cn=EISUsers,ou=Users,dc=moj,dc=com"
      ELASTICSEARCH_URL                 = "https://probation-search-dev.hmpps.service.justice.gov.uk/delius"
      GDPR_URL                          = "/gdpr/ui/homepage" # GDPR not deployed to CP yet, <URL>/gdpr/ui/homepage
      JDBC_CONNECTION_POOL_MAX_CAPACITY = "100"
      JDBC_CONNECTION_POOL_MIN_CAPACITY = "50"
      JDBC_URL                          = "jdbc:oracle:thin:@(DESCRIPTION=(LOAD_BALANCE=OFF)(FAILOVER=ON)(CONNECT_TIMEOUT=10)(RETRY_COUNT=3)(ADDRESS_LIST=(ADDRESS=(PROTOCOL=tcp)(HOST=delius-core-dev-db-1.hmpps-development.modernisation-platform.internal)(PORT=1521))(ADDRESS=(PROTOCOL=tcp)(HOST=delius-core-dev-db-2.hmpps-development.modernisation-platform.internal)(PORT=1521))(ADDRESS=(PROTOCOL=tcp)(HOST=delius-core-dev-db-3.hmpps-development.modernisation-platform.internal)(PORT=1521)))(CONNECT_DATA=(SERVICE_NAME=DMDNDA_TAF)))"
      JDBC_USERNAME                     = "delius_pool"
      LDAP_HOST                         = "https://ldap.dev.delius-core.hmpps-development.modernisation-platform.service.justice.gov.uk"
      LDAP_PRINCIPAL                    = "cn=admin,dc=moj,dc=com"
      LOG_LEVEL_NDELIUS                 = "DEBUG"
      MERGE_API_URL                     = "https://delius-merge-api-dev.hmpps.service.justice.gov.uk"
      MERGE_OAUTH_URL                   = "https://delius-user-management-dev.hmpps.service.justice.gov.uk/umt/oauth/"
      MERGE_URL                         = "https://delius-merge-ui-dev.hmpps.service.justice.gov.uk"
      NDELIUS_CLIENT_ID                 = "migrations_client_id"
      OAUTH_CALLBACK_URL                = "https://ndelius.dev.delius-core.hmpps-development.modernisation-platform.service.justice.gov.uk/NDelius-war/delius/JSP/auth/token.jsp"
      OAUTH_CLIENT_ID                   = "delius-ui"
      OAUTH_DEFAULT_SCOPE               = "delius"
      OAUTH_LOGIN_ENABLED               = "false"
      OAUTH_LOGIN_NAME                  = ""
      OAUTH_TOKEN_VERIFICATION_URL      = "https://token-verification-api-dev.prison.service.justice.gov.uk/token/verify"
      OAUTH_URL                         = "https://sign-in-dev.hmpps.service.justice.gov.uk/auth"
      OFFENDER_SEARCH_API_URL           = "https://probation-offender-search-dev.hmpps.service.justice.gov.uk"
      PASSWORD_RESET_URL                = "https://pwm.dev.delius-core.hmpps-development.modernisation-platform.service.justice.gov.uk/public/forgottenpassword"
      PDFCREATION_TEMPLATES             = "shortFormatPreSentenceReport|paroleParom1Report|oralReport"
      PDFCREATION_URL                   = "https://ndelius-new-tech-pdf-generator-dev.hmpps.service.justice.gov.uk/newTech"
      PREPARE_CASE_FOR_SENTENCE_URL     = "https://prepare-a-case-dev.apps.live-1.cloud-platform.service.justice.gov.uk"
      PSR_SERVICE_URL                   = "https://pre-sentence-service-dev.hmpps.service.justice.gov.uk"
      TRAINING_MODE_APP_NAME            = "National Delius - TEST USE ONLY"
      TZ                                = "Europe/London"
      USERMANAGEMENT_URL                = "https://delius-user-management-dev.hmpps.service.justice.gov.uk/umt/"
      USER_CONTEXT                      = "ou=Users,dc=moj,dc=com"
      USER_MEM_ARGS                     = "-XX:MaxRAMPercentage=90.0"
    }

    weblogic_eis = {
      image_tag                = "6.3.9-eis"
      container_port           = 8080
      container_memory         = 4096
      container_cpu            = 2048
      task_definition_revision = 12
    }

    pwm = {
      image_tag        = "8250538047-1"
      container_port   = 8080
      container_cpu    = 512
      container_memory = 1024
    }

    ldap = {
      image_tag        = "6.1.3-latest"
      container_port   = 389
      slapd_log_level  = "stats"
      container_cpu    = 512
      container_memory = 1024
    }

    sfs = {
      container_cpu    = 2048
      container_memory = 4096
    }

    oracle_observer = {
      image_tag        = "latest"
      container_cpu    = 512
      container_memory = 1024
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
    engine_version             = "3.5.4"
    # This map overlaps with the Ansible database configuration in delius-environment-configuration-management/ansible/group_vars
    # Please ensure any changes made here are consistent with Ansible variables.
    audit_source_endpoint = {
      read_host     = "standbydb2"
      read_database = "${local.db_config_dev.database_name}S2"
    }
    audit_target_endpoint = {
      write_environment = "test"
    }
    user_source_endpoint = {}
    user_target_endpoint = {
      write_database = local.db_config_dev.database_name
    }
    is-production = false
    # Times must be specified in UTC
    disable_latency_alarms = {
      start_time      = "19:59"
      end_time        = "06:45"
      disable_weekend = true
    }
  }
}

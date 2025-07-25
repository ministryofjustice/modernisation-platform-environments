#### This file can be used to store locals specific to the member account ####
locals {
  # General
  region = "eu-west-2"

  # RDS
  appstream_cidr             = "10.200.32.0/19"
  cidr_ire_workspace         = "10.200.96.0/19"
  workspaces_cidr            = local.application_data.accounts[local.environment].london_workspace_cidr
  cp_vpc_cidr                = local.application_data.accounts[local.environment].cp_vpc_cidr
  analytic_platform_cidr     = local.application_data.accounts[local.environment].analytic_platform_cidr
  lz_vpc                     = local.application_data.accounts[local.environment].landing_zone_vpc_cidr
  auto_minor_version_upgrade = false
  backup_retention_period    = "35"
  character_set_name         = "WE8MSWIN1252"
  instance_class             = "db.m5.large"
  engine                     = "oracle-se2"
  engine_version             = "19.0.0.0.ru-2025-04.rur-2025-04.r1"
  username                   = "sysdba"
  backup_window              = "22:00-01:00"
  maintenance_window         = "Mon:01:15-Mon:06:00"
  storage_type               = "gp2"
  rds_snapshot_name          = "laws3169-mojfin-migration-v1"
  deletion_production        = local.application_data.accounts[local.environment].deletion_protection
  ca_cert_identifier         = "rds-ca-rsa4096-g1"


  # CloudWatch Alarms
  cpu_threshold                     = "90"
  cpu_alert_period                  = "60"
  cpu_evaluation_period             = "30"
  memory_threshold                  = "1000000000"
  memory_alert_period               = "60"
  memory_evaluation_period          = "10"
  disk_free_space_threshold         = "100000000000"
  disk_free_space_alert_period      = "60"
  disk_free_space_evaluation_period = "1"
  read_latency_threshold            = "0.5"
  read_latency_alert_period         = "60"
  read_latency_evaluation_period    = "5"

  # PagerDuty Integration
  sns_topic_name                 = "${local.application_name}-${local.environment}-alerting-topic"
  pagerduty_integration_keys     = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
  pagerduty_integration_key_name = local.application_data.accounts[local.environment].pagerduty_integration_key_name

  # DB Link Secrets
  dblink_secrets = {
    secret1 = {
      name         = "APP_MOJFIN_APPS_RO"
      description  = "APPS_RO password for mojfin db link"
      secret_value = random_password.apps_ro_password.result
    },
    secret2 = {
      name         = "APP_MOJFIN_DEVELOPER"
      description  = "DEVELOPER user for TAD and TAD_TEST db link"
      secret_value = "laa_developer"
    },
    secret3 = {
      name         = "APP_MOJFIN_FEDUSER"
      description  = "FEDUSER user for EDW005"
      secret_value = "fed1ser"
    },
    secret4 = {
      name         = "APP_MOJFIN_FINACC"
      description  = "FINACC user for CISRO db link"
      secret_value = "Greenland"
    },
    secret5 = {
      name         = "APP_MOJFIN_MI_TEAM"
      description  = "ID for OBIEE connection to MOJFIN"
      secret_value = "MI_TEAM1"
    },
    secret6 = {
      name         = "APP_MOJFIN_MORA-W"
      description  = "MORA-W user for CISPROD db link"
      secret_value = "palace"
    },
    secret7 = {
      name         = "APP_MOJFIN_QUERY"
      description  = "Query user for CCMT db link"
      secret_value = "query1"
    }
  }

  prod_domain_name = "laa-finance-data.service.justice.gov.uk"
}

locals {
  environment_configuration = local.environment_configurations[local.environment]
  rds_major_engine_version  = split(".", local.environment_configuration.rds.engine_version)[0]

  environment_configurations = {
    development = {
      app_hostname = "development.data-platform.service.justice.gov.uk"
      app_ingress_allowlist = [
        "128.77.75.64/26", # Prisma Corporate
      ]
      rds = {
        engine_version          = "18.4"
        instance_class          = "db.t4g.small"
        allocated_storage       = 20
        max_allocated_storage   = 100
        multi_az                = false
        backup_retention_period = 1
        monitoring_interval     = 0
      }
    }
    test = {
      app_hostname = "test.data-platform.service.justice.gov.uk"
      app_ingress_allowlist = [
        "128.77.75.64/26", # Prisma Corporate
      ]
      rds = {
        engine_version          = "18.4"
        instance_class          = "db.t4g.small"
        allocated_storage       = 20
        max_allocated_storage   = 100
        multi_az                = false
        backup_retention_period = 1
        monitoring_interval     = 0
      }
    }
    preproduction = {
      app_hostname = "preproduction.data-platform.service.justice.gov.uk"
      app_ingress_allowlist = [
        "128.77.75.64/26", # Prisma Corporate
      ]
      rds = {
        engine_version          = "18.4"
        instance_class          = "db.t4g.small"
        allocated_storage       = 20
        max_allocated_storage   = 100
        multi_az                = true
        backup_retention_period = 7
        monitoring_interval     = 0
      }
    }
    production = {
      app_hostname = "data-platform.service.justice.gov.uk"
      app_ingress_allowlist = [
        "128.77.75.64/26", # Prisma Corporate
      ]
      rds = {
        engine_version          = "18.4"
        instance_class          = "db.t4g.medium"
        allocated_storage       = 100
        max_allocated_storage   = 250
        multi_az                = true
        backup_retention_period = 7
        monitoring_interval     = 60
      }
    }
  }
}

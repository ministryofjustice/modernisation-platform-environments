locals {
  environment_configuration = local.environment_configurations[local.environment]
  rds_major_engine_version  = split(".", local.environment_configuration.rds.engine_version)[0]

  environment_configurations = {
    development = {
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

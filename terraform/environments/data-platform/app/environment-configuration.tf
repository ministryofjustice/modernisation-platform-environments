locals {
  environment_configuration = local.environment_configurations[local.environment]
  rds_major_engine_version  = split(".", local.environment_configuration.rds_engine_version)[0]

  environment_configurations = {
    development = {
      rds_engine_version          = "18.4"
      rds_instance_class          = "db.t4g.small"
      rds_allocated_storage       = 20
      rds_max_allocated_storage   = 100
      rds_multi_az                = false
      rds_backup_retention_period = 1
      rds_monitoring_interval     = 0
    }
    test = {
      rds_engine_version          = "18.4"
      rds_instance_class          = "db.t4g.small"
      rds_allocated_storage       = 20
      rds_max_allocated_storage   = 100
      rds_multi_az                = false
      rds_backup_retention_period = 1
      rds_monitoring_interval     = 0
    }
    preproduction = {
      rds_engine_version          = "18.4"
      rds_instance_class          = "db.t4g.small"
      rds_allocated_storage       = 20
      rds_max_allocated_storage   = 100
      rds_multi_az                = true
      rds_backup_retention_period = 7
      rds_monitoring_interval     = 0
    }
    production = {
      rds_engine_version          = "18.4"
      rds_instance_class          = "db.t4g.medium"
      rds_allocated_storage       = 100
      rds_max_allocated_storage   = 250
      rds_multi_az                = true
      rds_backup_retention_period = 7
      rds_monitoring_interval     = 60
    }
  }
}

# Terraform configuration data for environments in delius-core development account

# Sample data
# tags demonstrate inheritance due to merges in the module
locals {
  test_config_baseline = {
    ec2_instances = {
      tags        = local.tags
      description = "set at the account level for test"
    }
  }

  test_config = {
    ec2_instances = {
      dev1-db-1 = {
        environment = "dev1"
        name        = "dbprimary" # Specific, resource-level value
        description = try(local.test_config_baseline.ec2_instances.description, "")
        tags = {
          "HA status" = "primary"
        }
      },
      dev1-db-2 = {
        environment = "dev1"
        name        = "dbsecondary"
        description = try(local.development_config_baseline.ec2_instances.description, "")
        tags = {
          "HA status" = "secondary"
        }
      },
      dev2-db-1 = {
        environment = "dev2"
        name        = "dbprimary"
        description = try(local.development_config_baseline.dev2.ec2_instances.description, "")
      },
      dev2-db-2 = {
        environment = "dev2"
        name        = "dbsecondary"
        description = try(local.development_config_baseline.dev2.ec2_instances.description, "")
      }
    }
  }
}

locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      /* VPC */
      connected_vpc_cidr            = "10.26.128.0/23"
      connected_vpc_private_subnets = ["10.26.128.0/26", "10.26.128.64/26", "10.26.128.128/26"]
      tariff_cidr                   = "10.26.32.0/21"

      /* CICA Source databases */
      source_database_sid           = "orauat6.eu-west-2.compute.internal"
      /* analytical-plafrom-ingestion-development resources */
      ap_data_glue_catalog_arn = "arn:aws:glue:eu-west-2:${local.environment_management.account_ids["analytical-platform-data-development"]}:catalog"
    }
    production = {
      /* VPC */
      connected_vpc_cidr            = "10.27.128.0/23"
      connected_vpc_private_subnets = ["10.27.128.0/26", "10.27.128.64/26", "10.27.128.128/26"]
      tariff_cidr                   = "10.27.80.0/21"

      /* CICA Source databases */
      source_database_sid           = "AddProductionDatabaseHere"
      /* analytical-plafrom-ingestion-production resources */
      ap_data_glue_catalog_arn = "arn:aws:glue:eu-west-2:${local.environment_management.account_ids["analytical-platform-data-production"]}:catalog"
    }
  }
}

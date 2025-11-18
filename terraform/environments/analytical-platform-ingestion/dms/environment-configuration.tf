locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {

      /* VPC */
      connected_vpc_cidr            = "10.26.128.0/23"
      connected_vpc_private_subnets = ["10.26.128.0/26", "10.26.128.64/26", "10.26.128.128/26"]
      tariff_cidr                   = "10.26.32.0/21"
      tempus_cidr                   = "10.12.16.0/21"

      /* CICA Source databases */
      source_database_sid = "orauat12"
      /* analytical-plafrom-ingestion-production resources */
      ap_data_glue_catalog_role = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/mojap-data-production-dms-ingress-development"
    }
    production = {

      /* VPC */
      connected_vpc_cidr            = "10.27.128.0/23"
      connected_vpc_private_subnets = ["10.27.128.0/26", "10.27.128.64/26", "10.27.128.128/26"]
      tariff_cidr                   = "10.27.80.0/21"
      tempus_cidr                   = "10.13.20.0/24"

      /* CICA Source databases */
      source_database_sid = "live.cica.gov.uk"
      /* analytical-plafrom-ingestion-production resources */
      ap_data_glue_catalog_role = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/mojap-data-production-dms-ingress-production"
    }
  }
}

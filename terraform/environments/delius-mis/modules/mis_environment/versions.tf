terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.16"
      configuration_aliases = [aws.bucket-replication, aws.core-vpc, aws.core-network-services]
    }
  }
  required_version = ">= 1.0.1"
}

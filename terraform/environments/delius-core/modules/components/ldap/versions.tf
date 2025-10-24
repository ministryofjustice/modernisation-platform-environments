terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.16"
      configuration_aliases = [aws.core-vpc, aws.core-network-services, aws.bucket-replication]
    }
  }
  required_version = ">= 1.0.1"
}

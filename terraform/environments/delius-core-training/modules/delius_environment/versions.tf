terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.bucket-replication, aws.core-vpc, aws.core-network-services, aws.modernisation-platform]
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
  required_version = ">= 1.0.1"
}

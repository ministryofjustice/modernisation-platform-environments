terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0, != 5.86.0"
      configuration_aliases = [aws.bucket-replication, aws.core-vpc, aws.core-network-services]
    }
  }
  required_version = ">= 1.0.1"
}

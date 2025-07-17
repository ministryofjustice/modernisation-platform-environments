terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.3"
      configuration_aliases = [aws.core-vpc, aws.core-network-services]
    }
  }
  required_version = ">= 1.0.1"
}

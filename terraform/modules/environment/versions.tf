terraform {
  required_providers {
    aws = {
      version               = "~> 5.0"
      source                = "hashicorp/aws"
      configuration_aliases = [aws.core-vpc, aws.core-network-services, aws.modernisation-platform]
    }
  }
  required_version = ">= 1.1.7"
}

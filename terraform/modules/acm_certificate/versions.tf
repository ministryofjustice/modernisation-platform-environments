terraform {
  required_providers {
    aws = {
      version               = "~> 5.0"
      source                = "hashicorp/aws"
      configuration_aliases = [aws.core-vpc, aws.core-network-services]
    }
  }
  required_version = "~> 1.5"
}

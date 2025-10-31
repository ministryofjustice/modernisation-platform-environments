terraform {
  required_providers {
    aws = {
      version               = "~> 6.0"
      source                = "hashicorp/aws"
      configuration_aliases = [aws.core-vpc, aws.core-network-services, aws.us-east-1]
    }
    random = {
      version = "~> 3.7.1"
      source  = "hashicorp/random"
    }
  }
  required_version = "~> 1.10"
}


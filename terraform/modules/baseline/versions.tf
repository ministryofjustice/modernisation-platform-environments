terraform {
  required_providers {
    aws = {
      version               = "~> 5.8"
      source                = "hashicorp/aws"
      configuration_aliases = [aws.core-vpc, aws.core-network-services, aws.us-east-1]
    }
    random = {
      version = "~> 3.6.3"
      source  = "hashicorp/random"
    }
  }
  required_version = "~> 1.5"
}

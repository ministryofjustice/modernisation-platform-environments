terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.16"
      configuration_aliases = [aws.core-vpc]
    }
  }
  required_version = ">= 1.0.1"
}

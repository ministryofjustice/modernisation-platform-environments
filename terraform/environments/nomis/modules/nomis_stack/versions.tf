terraform {
  required_providers {
    aws = {
      version               = "< 4.0.0"
      source                = "hashicorp/aws"
      configuration_aliases = [aws.core-vpc]
    }
  }
  required_version = ">= 1.0.1"
}

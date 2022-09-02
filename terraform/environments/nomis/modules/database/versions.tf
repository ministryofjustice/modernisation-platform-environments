terraform {
  required_providers {
    aws = {
      version               = "~> 4.9"
      source                = "hashicorp/aws"
      configuration_aliases = [aws.core-vpc]
    }
    cloudinit = {
      version = "~> 2.2"
      source  = "hashicorp/cloudinit"
    }

    random = {
      version = "= 3.4.1"
      source  = "hashicorp/random"
    }
  }
  required_version = ">= 1.1.7"
}

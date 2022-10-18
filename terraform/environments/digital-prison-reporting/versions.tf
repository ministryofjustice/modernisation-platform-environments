terraform {
  required_providers {
    aws = {
      version = "~> 4.0"
      source  = "hashicorp/aws"
    }

    random = {
      version = "= 3.4.1"
      source  = "hashicorp/random"
    }
  }
  required_version = "~> 1.0"
}
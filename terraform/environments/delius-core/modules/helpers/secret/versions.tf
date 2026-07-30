terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.16"
    }
    random = {
      version = "~> 3.9"
      source  = "hashicorp/random"
    }
  }
  required_version = ">= 1.0.1"
}

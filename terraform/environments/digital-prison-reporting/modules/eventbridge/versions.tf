terraform {
  required_version = "~> 1.10"
  required_providers {
    aws = {
      version = "~> 6.21"
      source  = "hashicorp/aws"
    }
  }
}
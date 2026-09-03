terraform {
  required_version = "~> 1.10"
  required_providers {
    aws = {
      version = "~> 6.62"
      source  = "hashicorp/aws"
    }
  }
}
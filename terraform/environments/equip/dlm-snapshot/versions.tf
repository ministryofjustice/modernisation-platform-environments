terraform {
  required_providers {
    aws = {
      version = "~> 5.4"
      source  = "hashicorp/aws"
    }
  }
  required_version = ">= 1.0.1"
}
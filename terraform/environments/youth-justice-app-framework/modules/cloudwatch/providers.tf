terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.3, != 5.86.0"
    }
  }
  required_version = ">= 1.0.1"
}
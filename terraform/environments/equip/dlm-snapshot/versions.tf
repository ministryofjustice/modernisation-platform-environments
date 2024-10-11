terraform {
  required_providers {
    aws = {
      version = "~> 5.0, != 5.71.0"
      source  = "hashicorp/aws"
    }
  }
  required_version = ">= 1.0.1"
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.20, != 5.86.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
  required_version = ">= 1.0.1"
}

terraform {
  required_providers {
    aws = {
      version = "~> 6.3, != 5.86.0"
      source  = "hashicorp/aws"
    }
  }
  required_version = ">= 1.0.1"
}

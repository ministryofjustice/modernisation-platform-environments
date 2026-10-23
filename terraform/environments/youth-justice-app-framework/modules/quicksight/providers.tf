terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.69, != 5.86.0"
    }
  }
  required_version = ">= 1.0.1"
}

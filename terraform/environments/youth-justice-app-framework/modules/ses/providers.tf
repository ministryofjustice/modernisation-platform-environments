terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0, != 5.86.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
  }
  required_version = ">= 1.0.1"
}

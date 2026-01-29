terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.27, != 5.86.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
  required_version = ">= 1.0.1"
}
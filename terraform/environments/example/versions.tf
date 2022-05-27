terraform {
  required_providers {
    aws = {
      version = "~> 4.9"
      source  = "hashicorp/aws"
    }
  }
  required_version = ">= 1.0.1"
}

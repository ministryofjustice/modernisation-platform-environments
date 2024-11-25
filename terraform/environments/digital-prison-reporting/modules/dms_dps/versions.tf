terraform {
  required_providers {
    aws = {
      version = ">= 5.77.0, < 6.0.0"
      source  = "hashicorp/aws"
    }
  }
  required_version = "~> 1.0"
}

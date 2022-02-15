terraform {
  required_providers {
    aws = {
      version = "~> 3.5.0"
      source  = "hashicorp/aws"
    }
  }
  required_version = ">= 1.0.1"
}

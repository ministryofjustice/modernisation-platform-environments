terraform {
  required_providers {
    aws = {
      version = "~> 4.9"
      source  = "hashicorp/aws"
    }
  }
  required_version = ">= 1.1.7"
}

terraform {
  required_providers {
    aws = {
      version = "~> 3.62"
      source  = "hashicorp/aws"
    }
  }
  required_version = ">= 1.1.0"
}

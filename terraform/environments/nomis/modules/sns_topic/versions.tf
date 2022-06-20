
terraform {
  required_version = ">= 1.1.7"
  required_providers {
    aws = {
      version               = "~> 4.9"
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}
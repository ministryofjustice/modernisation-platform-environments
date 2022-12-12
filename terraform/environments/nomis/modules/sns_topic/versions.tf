
terraform {
  required_version = ">= 1.1.7"
  required_providers {
    aws = {
      version = "= 4.46.0"
      source  = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}
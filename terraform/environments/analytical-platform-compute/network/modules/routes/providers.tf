terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0, != 5.86.0"
    }
  }
  required_version = "~> 1.0"
}

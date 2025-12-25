terraform {
  required_providers {
    aws = {
      version = "~> 6.20, != 5.86.0"
      source  = "hashicorp/aws"
    }

    random = {
      version = ">= 3.0.0"
      source  = "hashicorp/random"
    }

  }
  required_version = "~> 1.10"
}

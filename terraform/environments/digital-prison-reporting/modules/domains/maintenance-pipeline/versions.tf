terraform {
  required_providers {
    aws = {
      version = "~> 6.18, != 5.86.0"
      source  = "hashicorp/aws"
    }

  }
  required_version = "~> 1.10"
}

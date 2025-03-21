terraform {
  required_providers {
    aws = {
      version = "~> 5.0, != 5.86.0"
      source  = "hashicorp/aws"
    }

  }
  required_version = "~> 1.10"
}

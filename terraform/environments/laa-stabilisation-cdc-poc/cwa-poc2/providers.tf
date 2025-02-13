terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    aws.core-vpc = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
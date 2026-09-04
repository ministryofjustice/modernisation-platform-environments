terraform {
  required_providers {
    awscc = {
      source  = "hashicorp/awscc"
      version = "1.98.0"
    }
    null = {
      version = "~> 3.2"
      source  = "hashicorp/null"
    }
  }
}

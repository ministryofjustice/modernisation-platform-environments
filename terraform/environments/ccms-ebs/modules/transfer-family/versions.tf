terraform {
  required_providers {
    awscc = {
      source  = "hashicorp/awscc"
      version = "1.100.0"
    }
    null = {
      version = "~> 3.2"
      source  = "hashicorp/null"
    }
  }
}

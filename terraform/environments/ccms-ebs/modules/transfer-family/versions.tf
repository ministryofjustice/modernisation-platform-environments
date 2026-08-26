terraform {
  required_providers {
    awscc = {
      source  = "hashicorp/awscc"
      version = "1.49.0"
    }
    null = {
      version = "~> 3.2"
      source  = "hashicorp/null"
    }
  }
}

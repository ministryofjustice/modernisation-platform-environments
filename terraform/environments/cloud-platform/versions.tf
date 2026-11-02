terraform {
  required_providers {
    aws = {
      version = "~> 6.0, != 6.57.0"
      source  = "hashicorp/aws"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "~> 2.6"
    }
  }
  required_version = "~> 1.0"
}

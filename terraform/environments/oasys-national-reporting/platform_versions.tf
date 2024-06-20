terraform {
  required_providers {
    aws = {
      version = "5.53.0" # hardcoded from "~> 5.0" as currently broken, fix expected in 5.57.0 - change back when this is released
      source  = "hashicorp/aws"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
  }
  required_version = "~> 1.0"
}

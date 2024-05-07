terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.bucket-replication]
    }
  }
  required_version = ">= 1.0.1"
}

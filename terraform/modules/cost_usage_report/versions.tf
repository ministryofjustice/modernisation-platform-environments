terraform {
  required_providers {
    aws = {
      version               = "~> 5.0"
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us-east-1, aws.bucket-replication]
    }
  }
  required_version = "~> 1.10"
}

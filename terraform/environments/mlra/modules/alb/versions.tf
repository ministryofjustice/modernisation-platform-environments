terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.core-vpc,
        aws.core-network-services,
        aws.bucket-replication,
        aws.us-east-1]
    }
  }
  required_version = ">= 1.0.1"
}

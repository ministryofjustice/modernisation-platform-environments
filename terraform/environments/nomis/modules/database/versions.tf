terraform {
  required_providers {
    aws = {
      version               = "~> 3.62"
      source                = "hashicorp/aws"
      configuration_aliases = [aws.core-vpc]
    }
  }
}

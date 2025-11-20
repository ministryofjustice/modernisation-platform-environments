terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.21"
      configuration_aliases = [aws.sso]
    }
  }
  required_version = "~> 1.0"
}

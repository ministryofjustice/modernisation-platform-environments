terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.sso]
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.0"
    }
  }
  required_version = "~> 1.0"
}

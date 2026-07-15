provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      Terraform   = "true"
      Environment = terraform.workspace
      Component   = "namespaces/team-a"
    }
  }
}

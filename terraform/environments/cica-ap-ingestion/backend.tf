terraform {
  backend "s3" {
    acl            = "private"
    encrypt        = true
    region         = "eu-west-1"
  }
}


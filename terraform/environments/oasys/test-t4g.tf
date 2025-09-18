resource "aws_instance" "my_instance" {

  count         = local.is-development ? 1 : 0
  ami           = "ami-08f714c552929eda9"
  instance_type = "t4g.micro"
}

locals {
  options = {

    sns_topics = {
      pagerduty_integrations = {
        pagerduty = "local.baseline_development"
      }
    }
  }
}

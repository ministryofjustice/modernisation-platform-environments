data "aws_security_group" "alb" {
  name = "${local.application_name}-prototypes-prototype-alb"
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["${terraform.workspace}"]
  }
}
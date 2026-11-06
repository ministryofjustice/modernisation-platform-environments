data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["${terraform.workspace}"]
  }
}
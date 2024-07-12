#### This file can be used to store data specific to the member account ####
data "aws_ami" "shared_ami" {
  most_recent = true
  filter {
    name   = "image-id"
    values = ["ami-0b03540afffcc04dd"]
  }
}

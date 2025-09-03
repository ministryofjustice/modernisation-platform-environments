#### This file can be used to store data specific to the member account ####
data "aws_ami" "shared_ami" {
  most_recent = true
  filter {
    name   = "image-id"
    values = ["ami-0b03540afffcc04dd"]
  }
}

data "aws_ami" "shared_db_ami" {
  count       = local.environment == "production" ? 1 : 0
  most_recent = true
  filter {
    name   = "image-id"
    values = ["ami-0fbb74a6acb7280db"]
  }
}

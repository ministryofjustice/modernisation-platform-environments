#### This file can be used to store data specific to the member account ####
data "aws_instances" "chaps_instances" {
  filter {
    name   = "tag:Name"
    values = ["cdpt-chaps-cluster-scaling-group"] 
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}
#### This file can be used to store data specific to the member account ####
data "aws_route53_zone" "application_zone" {
  provider     = aws.core-network-services
  name         = "correspondence-handling-and-processing.service.justice.gov.uk."
  private_zone = false
}

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

data "aws_ecs_task_definition" "latest" {
  task_definition = aws_ecs_task_definition.chaps_yarp_task_definition.family
}
##################################################
# Modernisation Platform VPC
##################################################

data "aws_vpc" "mp_platforms_development" {
  filter {
    name   = "tag:Name"
    values = ["platforms-development"]
  }
}

##################################################
# Modernisation Platform Subnets
##################################################

data "aws_subnets" "mp_platforms_development_general_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.mp_platforms_development.id]
  }
  filter {
    name   = "tag:Name"
    values = ["platforms-development-general-private-*"]
  }
}

data "aws_vpc" "selected" {
  count = contains(local.enabled_workspaces, terraform.workspace) ? 1 : 0
  
  filter {
    name   = "tag:Name"
    values = ["${local.application_name}-${local.environment}"]
  }
}

data "aws_subnets" "eks_private" {
  count = contains(local.enabled_workspaces, terraform.workspace) ? 1 : 0
  
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected[0].id]
  }
  filter {
    name   = "tag:Name"
    values = ["cloud-platform-non-live-*-private-*"]
  }
}

data "aws_subnets" "eks_public" {
  count = contains(local.enabled_workspaces, terraform.workspace) ? 1 : 0
  
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected[0].id]
  }
  filter {
    name   = "tag:Name"
    values = ["cloud-platform-non-live-*-public-*"]
  }
}
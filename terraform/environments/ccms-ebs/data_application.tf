## AMI data blocks
/*
data "aws_ami" "oracle_base" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = [local.application_data.accounts[local.environment].orace_base_ami_name]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
data "aws_ami" "oracle_base_marketplace" {
  most_recent = true
  owners      = ["131827586825"]

  filter {
    name   = "name"
    values = [local.application_data.accounts[local.environment].orace_base_ami_name_mp]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
*/
data "aws_ami" "oracle_base_ready" {
  most_recent = true

  #owners = ["amazon"]
  #owners = ["self"]
  owners = [local.application_data.accounts[local.environment].ami_owner]
  filter {
    name   = "name"
    values = [local.application_data.accounts[local.environment].orace_base_ami_name_ready]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
data "aws_ami" "oracle_base_prereqs" {
  most_recent = true
  owners      = [local.application_data.accounts[local.environment].ami_owner]

  filter {
    name   = "name"
    values = [local.application_data.accounts[local.environment].orace_base_prereqs_ami_name]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


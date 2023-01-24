## AMI data blocks
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

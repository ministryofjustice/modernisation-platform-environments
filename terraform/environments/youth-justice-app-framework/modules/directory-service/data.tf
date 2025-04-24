#data resource to get the latest CIS Microsoft Windows Server 2022 Benchmark - Level 1 ami for use in both certs.tf and management.tf
data "aws_ami" "windows_2022" {
  most_recent = true
  owners      = ["aws-marketplace"] # Use this after Subscription 
  #  owners      = ["amazon"] # to remove
  filter {
    name   = "name"
    values = ["CIS Microsoft Windows Server 2022 Benchmark - Level 1 -*"] # Use this after Subscription 
    #  values = ["Windows_Server-2022-English-Full-Base-*"] # to be removed

  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}


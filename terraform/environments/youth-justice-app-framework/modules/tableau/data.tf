#data resource to get the latest CIS Microsoft Windows Server 2022 Benchmark - Level 1 ami for use in both certs.tf and management.tf
data "aws_ami" "app_ami" {
  most_recent = true
  owners      = ["aws-marketplace"] # Use this after Subscription 
  #  owners      = ["amazon"] # to remove
  filter {
    name   = "name"
    values = ["CIS Amazon Linux 2023 Benchmark - Level 1*"] # Use this after Subscription 

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


data "aws_secretsmanager_secret" "datadog-api-key" {
  arn = var.datadog-api-key-name
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.datadog-api-key.id
}


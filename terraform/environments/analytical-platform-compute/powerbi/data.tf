################################################################################
# PowerBI Gateway - Data Sources
################################################################################

# Get the latest Windows Server 2025 AMI
data "aws_ami" "windows_server_2025" {
  most_recent = true
  owners      = ["801119661308"] # Amazon

  filter {
    name   = "name"
    values = ["Windows_Server-2025-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

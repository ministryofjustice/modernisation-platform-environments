#Create an instance role to join Windows instances to your AWS Managed Microsoft AD domain
#trusted entity is ec2, 
resource "aws_iam_role" "join_ad_role" {
  name               = "join_ad_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
      "Action": "sts:AssumeRole",
      "Principal": {
          "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
      }
  ]
}
EOF
}

#attach policies AmazonSSMDirectoryServiceAccess and AmazonSSMManagedInstanceCore
resource "aws_iam_role_policy_attachment" "join_ad_role_policy_ad_access" {
  role       = aws_iam_role.join_ad_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess"
}

resource "aws_iam_role_policy_attachment" "join_ad_role_policy_core" {
  role       = aws_iam_role.join_ad_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#data resource to get the latest Microsoft Windows Server 2019 Base ami
data "aws_ami" "windows_2019" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
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

#Create an instance profile for your EC2 instance
resource "aws_iam_instance_profile" "ad_instance_profile" {
  name = "ad_instance_profile"
  role = aws_iam_role.join_ad_role.name
}

#create a security group for your EC2 instance
resource "aws_security_group" "ad_sg" {
  name        = "ad_management_server_sg"
  description = "Allow AD traffic"
  vpc_id      = var.ds_managed_ad_vpc_id
  ingress { #inbound on 3389 from my ip todo, better rules later
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["85.87.99.44/32"]
  }
  ingress { #inbound on 3389 from olivier ip todo, better rules later
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["145.224.92.80/32"]
  }
  ingress { #inbound on 3389 from my ip todo, better rules later
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  ingress { #inbound on mysql adfs service? todo, test removal
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  ingress { #inbound on 443 for adfs service?  todo, test removal
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  ingress { #inbound on 3389 from my ip todo, better rules later
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  ingress { #inbound on 3389 from my ip todo, better rules later
    from_port   = 88
    to_port     = 88
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  egress { #allow all out #todo filter this down
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
    protocol    = "-1"
  }
  ingress { #temp to investigate issues
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.vpc_cidr_block]
    description = "Allow all inbound from vpc"
    protocol    = "-1"
  }
  tags = merge({ "Name" = "mgmt-ad-instance" }, local.tags)
}

resource "random_password" "ad_instance_admin_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

#create a keypair for your EC2 instance
resource "aws_secretsmanager_secret" "ad_instance_admin_secret" {
  name        = "ad_instance_password_secret_1"
  description = "Local Admin for management instance" #todo do I need this?
  #kms_key_id = var.ds_managed_ad_secret_key
}

resource "aws_secretsmanager_secret_version" "ad_instance_admin_secret_version" {
  secret_id     = aws_secretsmanager_secret.ad_instance_admin_secret.id
  secret_string = random_password.ad_instance_admin_password.result
}

# Bootstrapping PowerShell Script
data "template_file" "windows-dc-userdata" {
  template = <<EOF
<powershell>
net user Administrator "$${admin_password}"
$Password = ConvertTo-SecureString "$${admin_password}" -AsPlainText -Force;
Add-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-WindowsFeature -Name GPMC,RSAT-AD-PowerShell,RSAT-AD-AdminCenter,RSAT-ADDS-Tools,RSAT-DNS-Server
# Get the network adapter interface index
$adapterIndex = (Get-NetAdapter | Where-Object { $_.Name -like '*Ethernet*' }).InterfaceIndex
# Set DNS server addresses 
$dnsServers = $${ad_dns_servers}
# Set the DNS server addresses for the specified network adapter
Set-DnsClientServerAddress -InterfaceIndex $adapterIndex -ServerAddresses $dnsServers
Restart-Computer -Force
</powershell>
EOF
  vars = {
    admin_password = random_password.ad_instance_admin_password.result
    ad_dns_servers = join(",", aws_directory_service_directory.ds_managed_ad.dns_ip_addresses)
  }
}


#Create an EC2 instance and automatically join the directory (management)
resource "aws_instance" "ad_instance" {
  ami                         = data.aws_ami.windows_2019.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.ad_instance_profile.name
  key_name                    = module.key_pair.key_pair_name
  subnet_id                   = var.management_subnet_id
  associate_public_ip_address = false
  vpc_security_group_ids      = ["${aws_security_group.ad_sg.id}"]
  tags                        = merge({ "Name" = "mgmt-ad-instance" }, local.tags)
  user_data                   = data.template_file.windows-dc-userdata.rendered
  ebs_optimized               = true
  lifecycle {
    ignore_changes = [ami]
  }
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    encrypted = true
    tags = merge(local.tags,
      { Name = "root-device-mgmt-ad-instance" },
      { device-name = "/dev/sda1" }
    )
  }
}


resource "aws_ssm_document" "ssm_document" {
  name          = "ssm_document_ad"
  document_type = "Command"
  content       = <<DOC
{
    "schemaVersion": "1.0",
    "description": "Automatic Domain Join Configuration",
    "runtimeConfig": {
        "aws:domainJoin": {
            "properties": {
                "directoryId": "${aws_directory_service_directory.ds_managed_ad.id}",
                "directoryName": "${aws_directory_service_directory.ds_managed_ad.name}",
                "dnsIpAddresses": ${jsonencode(aws_directory_service_directory.ds_managed_ad.dns_ip_addresses)}
            }
        }
    }
}
DOC
}

resource "aws_ssm_association" "associate_ssm" {
  name        = aws_ssm_document.ssm_document.name
  instance_id = aws_instance.ad_instance.id
}

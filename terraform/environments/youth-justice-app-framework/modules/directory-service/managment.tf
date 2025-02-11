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

#data resource to get the latest CIS Microsoft Windows Server 2019 Benchmark - Level 1 ami
data "aws_ami" "windows_2022" {
  most_recent = true
  # owners      = ["aws-marketplace"] # Use this after Subscription 
   owners      = ["amazon"]
 filter {
    name   = "name"
    values = ["CIS Microsoft Windows Server 2022 Benchmark - Level 1 -*"] # Use this after Subscription 
  # values = ["Windows_Server-2022-English-Full-Base-*"] # to be removed
    
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
  #checkov:skip=CKV_AWS_382:todo add better rules
  name        = "ad_management_server_sg"
  description = "Allow AD traffic"
  vpc_id      = var.ds_managed_ad_vpc_id
  ingress { #inbound on 3389 , better rules later, test if actually needed
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "LDAP"
  }
  ingress { #inbound on 3389 , better rules later, test if actually needed
    from_port   = 636
    to_port     = 636
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "LDAP"
  }
  ingress { #inbound on mysql adfs service? todo, test removal, test if actually needed
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "ADFS"
  }
  ingress { #inbound on 443 for adfs service?  todo, test removal, test if actually needed
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "ADFS"
  }
  ingress { #inbound on 3389 , todo better rules later, test if actually needed
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "LDAP"
  }
  ingress { #inbound on 3389 , todo better rules later, test if actually needed
    from_port   = 88
    to_port     = 88
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "LDAP"
  }
  egress { #allow all out #todo filter this down
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
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
  #checkov:skip=CKV2_AWS_57:todo add rotation if needed
  #checkov:skip=CKV_AWS_149: it is added
  name        = "ad_instance_password_secret_1"
  description = "Local Admin for management instance" #todo do I need this?
  kms_key_id  = var.ds_managed_ad_secret_key
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

# Create some standard folders that will be needed by the Initialisation Script
New-Item -Path "C:\"    -Name "i2N"      -ItemType Directory
New-Item -Path "C:\i2N" -Name "Software" -ItemType Directory
New-Item -Path "C:\i2N" -Name "Log"      -ItemType Directory

# Create a job to run following Restart
$trigger = New-JobTrigger -AtStartup -RandomDelay 00:00:30
Register-ScheduledJob -Name  Initialise-Server -Trigger $trigger -ScriptBlock {
  $logFile        = "C:\i2N\Log\Init_LogFile_$(Get-Date -Format "yyyyMMdd hhmm").log"

  Import-Module -Name International

  Write-Output "$(Get-Date) Set System Locale, etc." | Out-File  $logFile -Append

  Set-WinSystemLocale -SystemLocal en-GB
  Set-WinUILanguageOverride -Language en-GB
  Set-WinUserLanguageList -LanguageList en-GB -Force
  Set-WinSystemLocale en-GB
  Set-Culture en-GB
  Set-TimeZone -ID "GMT Standard Time"

  Write-Output "$(Get-Date) Install Software" | Out-File  $logFile -Append
  $Download_Folder = "C:\i2N\Software"
 
  #Download and install Firefox
  $Download = join-path $Download_Folder firefox.exe

  Invoke-WebRequest 'https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US'  -OutFile $Download
  Start-Process "$Download" -Wait -ArgumentList "/S"
  Write-Output "$(Get-Date) Firefox Installed" | Out-File  $logFile -Append


  #Download and install Notepad++
  $Download = join-path $Download_Folder npp.8.7.5.Installer.x64.exe

  Invoke-WebRequest 'https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.7.5/npp.8.7.5.Installer.x64.exe'  -OutFile $Download
  Start-Process "$Download_Folder" /S -NoNewWindow -Wait -PassThru -Wait
  Write-Output "$(Get-Date) Notepad++ installed" | Out-File  $logFile -Append


  #Download and install pgAdmin 4 v7.8
  $Download = join-path $Download_Folder pgadmin4-7.8-x64.exe

  Invoke-WebRequest 'https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v7.8/windows/pgadmin4-7.8-x64.exe'  -OutFile $Download
  Start-Process "$Download" -Wait -ArgumentList "/VERYSILENT /ALLUSERS /NORESTART"
  Write-Output "$(Get-Date) pgAdmin installed" | Out-File  $logFile -Append

  Write-Output "$(Get-Date) Installs Complete" | Out-File  $logFile -Append
  
  UnRegister-ScheduledJob -Name  Initialise-Server

  Write-Output "$(Get-Date) Initialise-Server Job Unregistered" | Out-File  $logFile -Append

}

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
  vpc_security_group_ids      = [aws_security_group.ad_sg.id]
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
  targets: [
    {
      Key: "InstanceIds",
      Values: [
        aws_instance.ad_instance.id
      ]
    }
  ]
#  instance_id = aws_instance.ad_instance.id
}

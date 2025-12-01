moved {
  from = aws_security_group.ad_sg
  to   = aws_security_group.mgmt_instance_sg
}

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

  tags = local.all_tags

}

#create a policy to all management instance to download files from the install-files bucket
resource "aws_iam_policy" "read_s3" {
  name        = "read_s3_transfer_and_install_files"
  description = "Use to enable ec2 Instances to retrieve software from S3 bucket <enviroment>-install-files"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::${local.environment_name}-install-files/*",
          "arn:aws:s3:::${local.environment_name}-install-files",
          "arn:aws:s3:::${local.environment_name}-transfer/*",
          "arn:aws:s3:::${local.environment_name}-transfer"
        ]
      }
    ]
  })

  tags = local.all_tags
}

#attach policies Aread_s3_install_software
resource "aws_iam_role_policy_attachment" "join_ad_role_policy_s3_access" {
  role       = aws_iam_role.join_ad_role.name
  policy_arn = aws_iam_policy.read_s3.arn
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

resource "aws_iam_role_policy_attachment" "join_ad_role_policy_Cloudwatch" {
  role       = aws_iam_role.join_ad_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#Create an instance profile for your EC2 instance
resource "aws_iam_instance_profile" "ad_instance_profile" {
  name = "ad_instance_profile"
  role = aws_iam_role.join_ad_role.name
}

#create a security group for your EC2 instance
resource "aws_security_group" "mgmt_instance_sg" {
  name_prefix = "ad_management_server_sg"
  description = "Management Server Access"
  vpc_id      = var.ds_managed_ad_vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge({ "Name" = "ad_management_server_sg" }, local.all_tags)
}

resource "aws_vpc_security_group_egress_rule" "allow_http_out" { #allow HTTP outbound to everywhere
  security_group_id = aws_security_group.mgmt_instance_sg.id

  from_port   = 80
  to_port     = 80
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow HTTP outbound"
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_https_out" { #allow HTTPS outbound to everywhere
  security_group_id = aws_security_group.mgmt_instance_sg.id

  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow HTTPS outbound"
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_any_to_ad" { #allow Unrestricted accedss to AD
  security_group_id            = aws_security_group.mgmt_instance_sg.id
  referenced_security_group_id = aws_directory_service_directory.ds_managed_ad.security_group_id

  description = "Allow Unrestricted access to AD"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_out_to_rds" { #allow PostgreSQL outbound to RDS
  security_group_id            = aws_security_group.mgmt_instance_sg.id
  referenced_security_group_id = var.rds_cluster_security_group_id

  from_port   = 5432
  to_port     = 5432
  description = "Allow Management Instance to RDS PostgreSQL"
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_out_to_esb" { #allow ssh outbound to ESB
  security_group_id            = aws_security_group.mgmt_instance_sg.id
  referenced_security_group_id = var.esb_security_group_id

  from_port   = 22
  to_port     = 22
  description = "Allow Management Instance to ssh to ESB"
  ip_protocol = "tcp"
}



# Retrieve the RDS SG so that a roule can be addedd to enable access from the Management instance
data "aws_security_group" "rds_sg" {
  id = var.rds_cluster_security_group_id
}

resource "aws_vpc_security_group_ingress_rule" "allow_in_to_rds" { #allow PostgreSQL from AD management to RDS
  security_group_id            = data.aws_security_group.rds_sg.id
  referenced_security_group_id = aws_security_group.mgmt_instance_sg.id
  from_port                    = 5432
  to_port                      = 5432
  description                  = "Allow AD Management Instance to RDS PostgreSQL"
  ip_protocol                  = "tcp"

  tags = local.all_tags
}

# Retrieve the ID of the Security Group created by Cloud Formation while building the KPI instances.
data "aws_security_group" "ca_sg" {
  tags = {
    Name = "CertificateAuthoritySecurityGroup"
  }

  depends_on = [aws_cloudformation_stack.pki_quickstart]
}

resource "aws_vpc_security_group_egress_rule" "allow_out_to_ca" { #allow unlimited access to the Certificate Authority
  security_group_id            = aws_security_group.mgmt_instance_sg.id
  referenced_security_group_id = data.aws_security_group.ca_sg.id

  description = "Allow Management Instance to RDS PostgreSQL"
  ip_protocol = "-1"
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

  tags = local.all_tags
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
New-Item -Path "C:\i2N" -Name "Scripts"  -ItemType Directory

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
  Start-Process "$Download" /S -NoNewWindow -Wait -PassThru -Wait
  Write-Output "$(Get-Date) Notepad++ installed" | Out-File  $logFile -Append


  #Download and install pgAdmin 4 v7.8
  $Download = join-path $Download_Folder pgadmin4-9.0-x64.exe

  Invoke-WebRequest 'https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v9.0/windows/pgadmin4-9.0-x64.exe'  -OutFile $Download
  Start-Process "$Download" -Wait -ArgumentList "/VERYSILENT /ALLUSERS /NORESTART"
  Write-Output "$(Get-Date) pgAdmin installed" | Out-File  $logFile -Append

  Write-Output "$(Get-Date) Installs Complete" | Out-File  $logFile -Append

  # Remove the following module as it prevents the PowerShell command window from accepting kekboard input on W2022
  Remove-Module PSReadLine
  Write-Output "$(Get-Date) PowerShell Module PSReadLie removed" | Out-File  $logFile -Append
  
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
  count = var.ad_management_instance_count

  ami                         = data.aws_ami.windows_2022.id
  instance_type               = "M6i.xlarge"
  iam_instance_profile        = aws_iam_instance_profile.ad_instance_profile.name
  key_name                    = module.key_pair.key_pair_name
  subnet_id                   = var.private_subnet_ids[count.index % length(var.private_subnet_ids)] # 1st in Subnet a, then b, c, a, etc
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.mgmt_instance_sg.id]

  tags = merge(local.all_tags,
    { "Name" = "mgmt-ad-instance-${count.index + 1}" },
    { "OS" = "Windows" },
    { "PatchingSchedule" = "Windows1" }
  )

  user_data     = data.template_file.windows-dc-userdata.rendered
  ebs_optimized = true
  lifecycle {
    ignore_changes = [ami]
  }
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    encrypted   = true
    volume_size = 50
    tags = merge(local.all_tags,
      { Name = "root-device-mgmt-ad-instance" },
      { device-name = "/dev/sda1" }
    )
  }
}


resource "aws_ssm_document" "ssm_document" {
  name          = "ssm_document_ad_schema2.2"
  document_type = "Command"
  content       = <<DOC
{
  "schemaVersion": "2.2",
  "description": "aws:domainJoin",
   "mainSteps": [
    {
      "action": "aws:domainJoin",
      "name": "domainJoin",
      "inputs": {
        "directoryId": "${aws_directory_service_directory.ds_managed_ad.id}",
        "directoryName": "${aws_directory_service_directory.ds_managed_ad.name}",
        "dnsIpAddresses": ${jsonencode(aws_directory_service_directory.ds_managed_ad.dns_ip_addresses)}
      }
    }
  ]
}
DOC
}

resource "aws_ssm_association" "associate_ssm" {

  name = aws_ssm_document.ssm_document.name
  targets {
    key    = "InstanceIds"
    values = aws_instance.ad_instance[*].id
  }
  max_concurrency = 1 # Tihs might resolved the issue of the first run failing on the 2nd instance.

  #  instance_id = aws_instance.ad_instance.id
}

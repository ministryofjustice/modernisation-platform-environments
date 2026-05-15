##############################################
### EC2 Instance for User Creation
### 
### Windows Server instance that joins the AD domain
### and runs PowerShell scripts to create AD users
### via Lambda + SSM
##############################################

# Latest Windows Server 2022 AMI
data "aws_ami" "windows_2022" {
  count = local.environment == "development" ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Store AD admin password for domain join
resource "aws_ssm_parameter" "ad_admin_password_for_ec2" {
  count = local.environment == "development" ? 1 : 0

  name        = "/${local.application_name}/${local.environment}/ad-admin-password"
  description = "AD Admin password for EC2 domain join"
  type        = "SecureString"
  value       = random_password.ad_admin_password[0].result

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-ad-admin-password" }
  )
}

# Note: Service account password is created in xxx-new-service-account.tf

resource "aws_instance" "user_creation_ec2" {
  count = local.environment == "development" ? 1 : 0

  ami                    = data.aws_ami.windows_2022[0].id
  instance_type          = "t3.medium"
  iam_instance_profile   = aws_iam_instance_profile.user_creation_ec2_profile[0].name
  subnet_id              = data.terraform_remote_state.workspace_components.outputs.private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.user_creation_ec2_sg[0].id]

  # Domain join and script deployment configuration
  user_data = <<-USERDATA
    <powershell>
    # Join domain
    $domain = "${local.application_data.accounts[local.environment].ad_directory_name}"
    $password = "${random_password.ad_admin_password[0].result}" | ConvertTo-SecureString -AsPlainText -Force
    $username = "Admin"
    $credential = New-Object System.Management.Automation.PSCredential("$domain\$username", $password)
    
    Add-Computer -DomainName $domain -Credential $credential -Restart -Force
    </powershell>
    <persist>true</persist>
    <powershell>
    # This runs after domain join restart
    # Install AD PowerShell tools
    Install-WindowsFeature -Name RSAT-AD-PowerShell
    
    # Create the user creation script
    $scriptContent = @'
${file("${path.module}/xxx-new-scripts/user-creation.ps1")}
'@
    
    $scriptContent | Out-File -FilePath "C:\Windows\system32\user-creation.ps1" -Encoding UTF8
    Write-Host "User creation script deployed successfully"
    </powershell>
  USERDATA

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    encrypted             = true
    delete_on_termination = true
    kms_key_id            = aws_kms_key.ebs[0].arn
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(
    local.tags,
    {
      "Name"   = "${local.application_name}-${local.environment}-user-creation-ec2"
      "Purpose" = "AD user creation automation"
      "Backup" = "false"
    }
  )

  lifecycle {
    ignore_changes = [
      user_data,
      ami
    ]
  }

  depends_on = [
    terraform_data.lambda_service_account,
    aws_ssm_parameter.lambda_service_account_password
  ]
}

##############################################
### Outputs
##############################################

output "user_creation_ec2_instance_id" {
  value       = local.environment == "development" ? aws_instance.user_creation_ec2[0].id : null
  description = "EC2 instance ID for user creation automation"
}

output "user_creation_ec2_private_ip" {
  value       = local.environment == "development" ? aws_instance.user_creation_ec2[0].private_ip : null
  description = "Private IP of user creation EC2 instance"
}

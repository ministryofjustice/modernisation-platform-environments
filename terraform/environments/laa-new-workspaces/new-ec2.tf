##############################################
### EC2 Instance for User Creation
### 
### Windows Server instance that joins the AD domain
### and runs PowerShell scripts to create AD users
### via Lambda + SSM
##############################################

# Latest Windows Server 2022 AMI
data "aws_ami" "windows_2022" {

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

  name        = "/${local.application_name}/${local.environment}/ad-admin-password"
  description = "AD Admin password for EC2 domain join"
  type        = "SecureString"
  value       = random_password.ad_admin_password.result

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-ad-admin-password" }
  )
}

# Note: Service account password is created in xxx-new-service-account.tf

resource "aws_instance" "user_creation_ec2" {

  ami                    = data.aws_ami.windows_2022.id
  instance_type          = "t3.medium"
  iam_instance_profile   = aws_iam_instance_profile.user_creation_ec2_profile.name
  subnet_id              = data.terraform_remote_state.workspace_components.outputs.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.user_creation_ec2_sg.id]

  # Domain join and script deployment configuration
  user_data = <<-USERDATA
    <powershell>
    # Set DNS servers to AD DNS before domain join
    $adDnsServers = @("10.200.1.245", "10.200.2.11")
    $interfaceAlias = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1).Name
    Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias -ServerAddresses $adDnsServers
    
    Write-Host "DNS servers configured: $adDnsServers"
    Start-Sleep -Seconds 5
    
    # Verify DNS resolution
    $dnsTest = Resolve-DnsName -Name "${local.application_data.accounts[local.environment].ad_directory_name}" -ErrorAction SilentlyContinue
    if ($dnsTest) {
        Write-Host "DNS resolution successful"
    } else {
        Write-Host "WARNING: DNS resolution failed, but continuing with domain join"
    }
    
    # Join domain
    $domain = "${local.application_data.accounts[local.environment].ad_directory_name}"
    $password = "${random_password.ad_admin_password.result}" | ConvertTo-SecureString -AsPlainText -Force
    $username = "Admin"
    $credential = New-Object System.Management.Automation.PSCredential("$domain\$username", $password)
    
    try {
        Add-Computer -DomainName $domain -Credential $credential -Restart -Force -ErrorAction Stop
        Write-Host "Domain join initiated, restarting..."
    } catch {
        Write-Host "Domain join failed: $_"
        Write-Host "Will retry after reboot..."
    }
    </powershell>
    <persist>true</persist>
    <powershell>
    # This runs after domain join restart
    # Re-set DNS servers (in case they were reset)
    $adDnsServers = @("10.200.1.245", "10.200.2.11")
    $interfaceAlias = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1).Name
    Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias -ServerAddresses $adDnsServers
    
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
    kms_key_id            = aws_kms_key.ebs.arn
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(
    local.tags,
    {
      "Name"    = "${local.application_name}-${local.environment}-user-creation-ec2"
      "Purpose" = "AD user creation automation"
      "Backup"  = "false"
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
  value       = local.environment == "development" ? aws_instance.user_creation_ec2.id : null
  description = "EC2 instance ID for user creation automation"
}

output "user_creation_ec2_private_ip" {
  value       = local.environment == "development" ? aws_instance.user_creation_ec2.private_ip : null
  description = "Private IP of user creation EC2 instance"
}

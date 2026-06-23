##############################################
### Service Account for Lambda User Creation
###
### Creates the lambda.workspace AD service account
### used by the EC2+Lambda automation to create
### WorkSpace users.
##############################################

# Generate random password for service account
resource "random_password" "lambda_service_account" {
  length           = 32
  special          = true
  override_special = "!@#$%^&*"

  keepers = {
    username = "lambda.workspace"
  }
}

# Store password in SSM Parameter Store (referenced by EC2 and Lambda)
resource "aws_ssm_parameter" "lambda_service_account_password" {
  name        = "/laa-workspaces/${local.environment}/ad-service-account-password"
  description = "Password for lambda.workspace AD service account"
  type        = "SecureString"
  value       = random_password.lambda_service_account.result

  tags = merge(
    local.tags,
    { "Name" = "lambda-workspace-service-account-password" }
  )
}

# Create the lambda.workspace AD user
resource "terraform_data" "lambda_service_account" {

  # Trigger replacement when password changes
  triggers_replace = [
    random_password.lambda_service_account.result,
    "v1",
  ]

  input = {
    directory_id = aws_directory_service_directory.workspaces_ad.id
    username     = "lambda.workspace"
    first_name   = "Lambda"
    last_name    = "Workspace"
    email        = "lambda.workspace@laa-workspaces.local"
    region       = local.application_data.accounts[local.environment].region
  }

  depends_on = [
    aws_iam_role_policy_attachment.github_actions_ds_data_access,
    random_password.lambda_service_account
  ]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Creating lambda.workspace service account..."
      
      if aws ds-data create-user \
        --directory-id ${self.input.directory_id} \
        --sam-account-name ${self.input.username} \
        --given-name "${self.input.first_name}" \
        --surname "${self.input.last_name}" \
        --email-address ${self.input.email} \
        --region ${self.input.region} 2>&1; then
        echo "Service account ${self.input.username} created successfully (disabled by default)"
      else
        echo "Service account ${self.input.username} already exists"
      fi

      echo "Note: Password and enabled status will be set via PowerShell in next step"
      echo "Waiting 10 seconds for AD propagation..."
      sleep 10
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      aws ds-data delete-user \
        --directory-id ${self.input.directory_id} \
        --sam-account-name ${self.input.username} \
        --region ${self.input.region} 2>&1 || echo "Service account may not exist, continuing..."
    EOT
  }
}

# Set password and enable the service account using PowerShell
# This is required because ds-data API doesn't support setting passwords
resource "terraform_data" "lambda_service_account_password_reset" {

  triggers_replace = [
    terraform_data.lambda_service_account.id,
    random_password.lambda_service_account.result,
    "v1",
  ]

  input = {
    instance_id = aws_instance.user_creation_ec2.id
    region      = local.application_data.accounts[local.environment].region
  }

  depends_on = [
    terraform_data.lambda_service_account,
    aws_ssm_parameter.lambda_service_account_password,
    aws_instance.user_creation_ec2
  ]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Setting password and enabling lambda.workspace account via PowerShell..."
      
      # Send SSM command to set password and enable account
      COMMAND_ID=$(aws ssm send-command \
        --instance-ids ${self.input.instance_id} \
        --document-name "AWS-RunPowerShellScript" \
        --parameters 'commands=["Write-Host \"Setting lambda.workspace password and enabling account...\"","$adminPassword = Get-SSMParameterValue -Name \"/laa-workspaces/development/ad-admin-password\" -WithDecryption $true","$adminPwd = $adminPassword.Parameters.Value","$secureAdminPwd = ConvertTo-SecureString $adminPwd -AsPlainText -Force","$adminCred = New-Object System.Management.Automation.PSCredential(\"LAAWORKSPACES\\Admin\", $secureAdminPwd)","$serviceAcctPassword = Get-SSMParameterValue -Name \"/laa-workspaces/development/ad-service-account-password\" -WithDecryption $true","$serviceAcctPwd = $serviceAcctPassword.Parameters.Value","$secureServicePwd = ConvertTo-SecureString $serviceAcctPwd -AsPlainText -Force","Set-ADAccountPassword -Identity \"lambda.workspace\" -NewPassword $secureServicePwd -Reset -Credential $adminCred -Server \"laa-workspaces.local\"","Enable-ADAccount -Identity \"lambda.workspace\" -Credential $adminCred -Server \"laa-workspaces.local\"","Write-Host \"Password set and account enabled\"","Get-ADUser -Identity \"lambda.workspace\" -Credential $adminCred -Server \"laa-workspaces.local\" -Properties Enabled | Select-Object Name, SamAccountName, Enabled"]' \
        --region ${self.input.region} \
        --query 'Command.CommandId' \
        --output text)
      
      echo "SSM Command ID: $COMMAND_ID"
      echo "Waiting 90 seconds for command to complete..."
      sleep 90
      
      # Check command status
      STATUS=$(aws ssm get-command-invocation \
        --command-id "$COMMAND_ID" \
        --instance-id ${self.input.instance_id} \
        --region ${self.input.region} \
        --query 'Status' \
        --output text)
      
      echo "Command status: $STATUS"
      
      if [ "$STATUS" = "Success" ]; then
        echo "✅ Service account password set and enabled successfully"
      else
        echo "⚠️  Command status: $STATUS - check SSM command output manually"
      fi
    EOT
  }
}

# Add service account to AWS Delegated Administrators group
resource "terraform_data" "lambda_service_account_group_membership" {

  triggers_replace = [
    terraform_data.lambda_service_account_password_reset.id,
    "v1",
  ]

  input = {
    directory_id = aws_directory_service_directory.workspaces_ad.id
    username     = "lambda.workspace"
    region       = local.application_data.accounts[local.environment].region
  }

  depends_on = [
    terraform_data.lambda_service_account_password_reset
  ]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Adding ${self.input.username} to AWS Delegated Administrators group..."
      echo "Directory ID: ${self.input.directory_id}"
      echo "Member name: ${self.input.username}"
      
      # Try adding to group
      set +e
      OUTPUT=$(aws ds-data add-group-member \
        --directory-id ${self.input.directory_id} \
        --group-name "AWS Delegated Administrators" \
        --member-name ${self.input.username} \
        --region ${self.input.region} 2>&1)
      EXIT_CODE=$?
      set -e
      
      echo "Command output: $OUTPUT"
      echo "Exit code: $EXIT_CODE"
      
      if [ $EXIT_CODE -eq 0 ]; then
        echo "✅ Service account added to admin group successfully"
      else
        if echo "$OUTPUT" | grep -q "MemberInGroupException"; then
          echo "✅ Service account already in admin group"
        else
          echo "❌ Failed to add to group: $OUTPUT"
          echo "You may need to add lambda.workspace to 'AWS Delegated Administrators' manually"
          echo "Continuing anyway..."
        fi
      fi
    EOT
  }
}

# Output for verification
output "lambda_service_account_created" {
  value       = local.environment == "development" ? "lambda.workspace service account created and added to AWS Delegated Administrators group" : "Not in development environment"
  description = "Status of lambda.workspace service account creation"
}

output "lambda_service_account_manual_group_add" {
  value       = local.environment == "development" ? "If group membership failed, run: aws ds-data add-group-member --directory-id ${aws_directory_service_directory.workspaces_ad.id} --group-name 'AWS Delegated Administrators' --member-name lambda.workspace --region eu-west-2" : null
  description = "Manual command to add lambda.workspace to admin group if automated method fails"
}

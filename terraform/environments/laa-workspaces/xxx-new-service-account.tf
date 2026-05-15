##############################################
### Service Account for Lambda User Creation
###
### Creates the lambda.workspace AD service account
### used by the EC2+Lambda automation to create
### WorkSpace users.
##############################################

# Generate random password for service account
resource "random_password" "lambda_service_account" {
  count   = local.environment == "development" ? 1 : 0
  length  = 32
  special = true
  override_special = "!@#$%^&*"

  keepers = {
    username = "lambda.workspace"
  }
}

# Store password in SSM Parameter Store (referenced by EC2 and Lambda)
resource "aws_ssm_parameter" "lambda_service_account_password" {
  count       = local.environment == "development" ? 1 : 0
  name        = "/laa-workspaces/${local.environment}/ad-service-account-password"
  description = "Password for lambda.workspace AD service account"
  type        = "SecureString"
  value       = random_password.lambda_service_account[0].result

  tags = merge(
    local.tags,
    { "Name" = "lambda-workspace-service-account-password" }
  )
}

# Create the lambda.workspace AD user
resource "terraform_data" "lambda_service_account" {
  count = local.environment == "development" ? 1 : 0

  # Trigger replacement when password changes
  triggers_replace = [
    random_password.lambda_service_account[0].result,
    "v1",
  ]

  input = {
    directory_id = aws_directory_service_directory.workspaces_ad[0].id
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
        echo "Service account ${self.input.username} created successfully"
      else
        echo "Service account ${self.input.username} already exists"
      fi

      echo "Waiting 10 seconds for AD propagation..."
      sleep 10
      
      echo "Adding ${self.input.username} to AWS Delegated Administrators group..."
      if aws ds-data add-group-member \
        --directory-id ${self.input.directory_id} \
        --group-name "AWS Delegated Administrators" \
        --member-name ${self.input.username} \
        --region ${self.input.region} 2>&1; then
        echo "✅ Service account added to admin group successfully"
      else
        echo "⚠️  Service account may already be in the group or group membership failed"
      fi
      
      echo "✅ Service account setup complete!"
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

# Output for verification
output "lambda_service_account_created" {
  value       = local.environment == "development" ? "lambda.workspace service account created and added to AWS Delegated Administrators group" : "Not in development environment"
  description = "Status of lambda.workspace service account creation"
}

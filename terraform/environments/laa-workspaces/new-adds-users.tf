##############################################
### AD User Creation
### Automatically creates/deletes AD users
### based on workspace_users in new-workspace-users.tf
##############################################

resource "terraform_data" "ad_users" {
  for_each = local.environment == "development" ? local.workspace_users : {}

  # Trigger replacement when user details change or version is bumped
  # Increment version to force user recreation if needed
  triggers_replace = [
    each.value.first_name,
    each.value.last_name,
    each.value.email,
    "v3", # Bump this to force recreation (v1 -> v2 -> v3, etc.)
  ]

  input = {
    directory_id = aws_directory_service_directory.workspaces_ad[0].id
    username     = each.key
    first_name   = each.value.first_name
    last_name    = each.value.last_name
    email        = each.value.email
    region       = local.application_data.accounts[local.environment].region
  }

  # Ensure IAM permissions are in place before attempting to create users
  depends_on = [
    aws_iam_role_policy_attachment.github_actions_ds_data_access
  ]

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for IAM policy to propagate (only needed on first apply)
      echo "Waiting 5 seconds for IAM policy propagation..."
      sleep 5
      
      # Try to create the user
      if aws ds-data create-user \
        --directory-id ${self.input.directory_id} \
        --sam-account-name ${self.input.username} \
        --given-name "${self.input.first_name}" \
        --surname "${self.input.last_name}" \
        --email-address ${self.input.email} \
        --region ${self.input.region} 2>&1; then
        echo "User ${self.input.username} created successfully"
      else
        # Check if user already exists
        if aws ds-data describe-user \
          --directory-id ${self.input.directory_id} \
          --sam-account-name ${self.input.username} \
          --region ${self.input.region} >/dev/null 2>&1; then
          echo "User ${self.input.username} already exists, continuing..."
        else
          echo "ERROR: Failed to create user ${self.input.username}"
          exit 1
        fi
      fi
      
      # Wait for AD propagation
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
        --region ${self.input.region} 2>&1 || echo "User ${self.input.username} may not exist, continuing..."
    EOT
  }
}
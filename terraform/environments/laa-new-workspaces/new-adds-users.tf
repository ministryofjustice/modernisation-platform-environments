##############################################
### AD User Creation via Directory Service Data API
###
### Creates users in AWS Managed Microsoft AD with full
### metadata (email, first name, last name). WorkSpaces reads
### these attributes via the ds-data API for console display
### and the "Invite user" functionality.
###
### When WorkSpaces auto-creates users it only sets
### sAMAccountName — it does NOT set mail/givenName/sn LDAP
### attributes. This resource ensures those are always set.
##############################################

resource "terraform_data" "ad_users" {
  for_each = local.environment == "development" ? local.workspace_users : {}

  # Trigger replacement when user details change or version is bumped
  # Increment version to force user re-sync if needed
  triggers_replace = [
    each.value.first_name,
    each.value.last_name,
    each.value.email,
    "v5",
  ]

  input = {
    directory_id = aws_directory_service_directory.workspaces_ad.id
    username     = each.key
    first_name   = each.value.first_name
    last_name    = each.value.last_name
    email        = each.value.email
    region       = local.application_data.accounts[local.environment].region
  }

  depends_on = [
    aws_iam_role_policy_attachment.github_actions_ds_data_access
  ]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting 15 seconds for IAM policy propagation..."
      sleep 15

      if aws ds-data create-user \
        --directory-id ${self.input.directory_id} \
        --sam-account-name ${self.input.username} \
        --given-name "${self.input.first_name}" \
        --surname "${self.input.last_name}" \
        --email-address ${self.input.email} \
        --region ${self.input.region} 2>&1; then
        echo "User ${self.input.username} created successfully"
      else
        echo "User ${self.input.username} already exists — updating metadata..."
        if aws ds-data update-user \
          --directory-id ${self.input.directory_id} \
          --sam-account-name ${self.input.username} \
          --given-name "${self.input.first_name}" \
          --surname "${self.input.last_name}" \
          --email-address ${self.input.email} \
          --region ${self.input.region} 2>&1; then
          echo "User ${self.input.username} metadata updated successfully"
        else
          echo "ERROR: Failed to create or update user ${self.input.username}"
          exit 1
        fi
      fi

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
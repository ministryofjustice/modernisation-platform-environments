##############################################
### AD User Creation
### Automatically creates/deletes AD users
### based on workspace_users in new-workspace-users.tf
##############################################

resource "terraform_data" "ad_users" {
  for_each = local.environment == "development" ? local.workspace_users : {}

  input = {
    directory_id = aws_directory_service_directory.workspaces_ad[0].id
    username     = each.key
    first_name   = each.value.first_name
    last_name    = each.value.last_name
    email        = each.value.email
    region       = local.application_data.accounts[local.environment].region
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws ds-data create-user \
        --directory-id ${self.output.directory_id} \
        --sam-account-name ${self.output.username} \
        --given-name "${self.output.first_name}" \
        --surname "${self.output.last_name}" \
        --email-address ${self.output.email} \
        --region ${self.output.region} 2>&1 || echo "User ${self.output.username} may already exist, continuing..."
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      aws ds-data delete-user \
        --directory-id ${self.output.directory_id} \
        --sam-account-name ${self.output.username} \
        --region ${self.output.region} 2>&1 || echo "User ${self.output.username} may not exist, continuing..."
    EOT
  }
}

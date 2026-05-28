##############################################
### WorkSpaces Users
###
### Add users to the map below to provision
### WorkSpaces. AD users are created automatically
### via the DS Data API (terraform_data.ad_users).
###
### Fields:
###   first_name    - User's first name
###   last_name     - User's last name
###   email         - User's email address
###   instance_type - "standard" or "performance"
###
### Example:
###   workspace_users = {
###     "john.smith" = {
###       first_name    = "John"
###       last_name     = "Smith"
###       email         = "john.smith@example.com"
###       instance_type = "standard"
###     }
###     "jane.doe" = {
###       first_name    = "Jane"
###       last_name     = "Doe"
###       email         = "jane.doe@example.com"
###       instance_type = "performance"
###     }
###   }
##############################################

locals {
  workspace_users = {
    # Add users here
    # 
    # Example (uncomment and modify):
    # "john.smith" = {
    #   first_name    = "John"
    #   last_name     = "Smith"
    #   email         = "john.smith@justice.gov.uk"
    #   instance_type = "standard"
    # }
    # "jane.doe" = {
    #   first_name    = "Jane"
    #   last_name     = "Doe"
    #   email         = "jane.doe@justice.gov.uk"
    #   instance_type = "performance"
    # }
  }
}

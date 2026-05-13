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
###   instance_type - "standard", "performance", or "power"
###
### Instance Types (Windows 10 on Server 2019):
###   standard:    2 vCPU, 4 GB RAM, 80 GB root, 50 GB user
###   performance: 2 vCPU, 8 GB RAM, 80 GB root, 100 GB user
###   power:       4 vCPU, 16 GB RAM, 175 GB root, 100 GB user
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
###       instance_type = "power"
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
    #   instance_type = "power"
    # }
  }
}

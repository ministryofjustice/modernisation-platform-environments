#### This file can be used to store locals specific to the member account ####

locals {
  # Skip test and preprod environments
  create_resources = contains(["development", "production"], local.environment)
}

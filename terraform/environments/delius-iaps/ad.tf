# Create Managed AD
resource "aws_directory_service_directory" "active_directory" {
  name        = "${local.application_name}-${local.environment}.local"
  short_name  = "${replace(local.application_name, "delius-", "")}-${local.environment}"   # Form "iaps-development" from "delius-iaps-development" because we need <= 15 chars for NETBIOS name 
  description = "Microsoft AD for ${local.environment}.local"

  type    = "MicrosoftAD"
  edition = "Standard"

  password   = aws_secretsmanager_secret_version.ad_password.secret_string
  enable_sso = false

  vpc_settings {
    vpc_id     = data.aws_vpc.shared.id
    subnet_ids = slice(data.aws_subnets.private-public.ids, 0, 2) # Retrieve the first 2 subnet ids - must be 2 because 2 DCs are created
  }

  tags = merge(
    local.tags,
    {},
  )

  # Required as AWS does not allow you to change the Admin password post AD Create - you must destroy/recreate 
  # When we run tf plan against an already created AD it will always show the AD needs destroy/create so we ignore
  lifecycle {
    ignore_changes = [
      password
    ]
  }
}

# Set up logging for the Managed AD
# To do...

# Set up auto-join domain doc for EC2 instances
# To do...
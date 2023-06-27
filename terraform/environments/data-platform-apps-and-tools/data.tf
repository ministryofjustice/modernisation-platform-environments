##################################################
# Data Platform Apps and Tools VPC
##################################################

# data "aws_vpc" "data_platform_apps_and_tools" {
#   filter {
#     name   = "tag:Name"
#     values = ["data-platform-apps-and-tools-${local.environment}"]
#   }
# }

##################################################
# Data Platform Apps and Tools Subnets
##################################################

# data "aws_subnets" "data_platform_apps_and_tools_private" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.data_platform_apps_and_tools.id]
#   }
#   filter {
#     name   = "tag:Name"
#     values = ["data-platform-apps-and-tools-${local.environment}-private-*"]
#   }
# }

# data "aws_subnets" "data_platform_apps_and_tools_public" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.data_platform_apps_and_tools.id]
#   }
#   filter {
#     name   = "tag:Name"
#     values = ["data-platform-apps-and-tools-${local.environment}-public-*"]
#   }
# }

##################################################
# Airflow SES
##################################################

# data "aws_secretsmanager_secret_version" "airflow_iam_access_key_id" {
#   secret_id = "/${local.application_name}/${local.environment}/airflow/iam-access-key-id"
# }

# data "aws_secretsmanager_secret_version" "airflow_iam_access_key_ses_smtp_password" {
#   secret_id = "/${local.application_name}/${local.environment}/airflow/iam-access-key-ses-smtp-password"
# }


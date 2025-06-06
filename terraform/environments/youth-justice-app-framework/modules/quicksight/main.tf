/*
# Subecription created manaulall as Git Actioos do not have sufficient permissions.
resource "aws_quicksight_account_subscription" "subscription" {
  count = var.environment == "development" ? 0 : 1 # subscription was created manually in develiopment

  account_name                     = "${var.project_name}-${var.environment}-moj"
  edition                          = "ENTERPRISE"
  authentication_method            = "IAM_AND_QUICKSIGHT"
  notification_email               = var.notification_email
  
}
*/

locals {
  vpc_connection_suffix = var.environment == "development" ? "-1" : ""
}

resource "aws_quicksight_vpc_connection" "local" {
  name               = "${var.project_name}-${var.environment}"
  vpc_connection_id  = "${var.project_name}-${var.environment}${local.vpc_connection_suffix}"
  role_arn           = aws_iam_role.vpc_connection_role.arn
  security_group_ids = [module.quicksight_sg.security_group_id]
  subnet_ids         = var.database_subnet_ids
  tags               = local.all_tags
}

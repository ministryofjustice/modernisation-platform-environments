resource "aws_quicksight_account_subscription" "subscription" {
  count = var.create_quicksight_subscription ? 1 : 0

  account_name                     = "${var.project_name}-${var.environment}-moj"
  edition                          = "ENTERPRISE"
  authentication_method            = "IAM_AND_QUICKSIGHT"
  notification_email               = var.notification_email
  
}

resource "aws_quicksight_vpc_connection" "local" {
  name               = "${var.project_name}-${var.environment}"
  vpc_connection_id  = "${var.project_name}-${var.environment}"
  role_arn           =  aws_iam_role.vpc_connection_role.arn
  security_group_ids = [module.quicksight_sg.security_group_id]
  subnet_ids         = var.database_subnet_ids
  tags               = local.all_tags
}

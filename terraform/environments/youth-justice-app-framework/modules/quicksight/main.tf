resource "aws_quicksight_account_subscription" "subscription" {
  account_name                     = "${var.project_name}-${var.environment}-moj"
  edition                          = "ENTERPRISE"
  authentication_method            = "IAM_AND_QUICKSIGHT"
  notification_email               = var.notification_email
  
}

resource "aws_quicksight_vpc_connection" "local" {
  name               = "${var.project_name}-${var.environment}"
  vpc_connection_id  = "${var.project_name}-${var.environment}"
  role_arn           =  data.aws_iam_role.quicksight.arn
  security_group_ids = [module.quicksight_sg.security_group_id]
  subnet_ids         = var.database_subnet_ids
  tags               = local.all_tags
}

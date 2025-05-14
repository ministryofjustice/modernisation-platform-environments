resource "aws_quicksight_vpc_connection" "local" {
  name               = "${var.project_name}-${var.environment}-3"
  vpc_connection_id  = "${var.project_name}-${var.environment}-3"
  role_arn           =  aws_iam_role.vpc_connection_role.arn
  security_group_ids = [module.quicksight_sg.security_group_id]
  subnet_ids         = var.database_subnet_ids
  tags               = local.all_tags
}

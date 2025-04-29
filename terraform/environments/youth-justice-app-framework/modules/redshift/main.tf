
resource "aws_redshiftserverless_namespace" "default" {
  #checkov:skip=CKV_AWS_282: tmp to get s3 user change in
  namespace_name = local.namespace_name

  admin_username        = "admin"
  manage_admin_password = true

  iam_roles = [
    aws_iam_role.redshift.arn, aws_iam_role.ycs-team.arn, aws_iam_role.yjb-moj-team.arn, aws_iam_role.yjb-team.arn
  ]

  kms_key_id = var.kms_key_arn

  log_exports = ["userlog", "connectionlog", "useractivitylog"]

  tags = merge(local.all_tags,
    { Name = local.namespace_name }
  )

}

# Create the Redshift Serverless Workgroup
resource "aws_redshiftserverless_workgroup" "default" {
  depends_on = [aws_redshiftserverless_namespace.default]

  namespace_name = aws_redshiftserverless_namespace.default.id
  workgroup_name = aws_redshiftserverless_namespace.default.id
  # base_capacity  = var.redshift_serverless_base_capacity

  security_group_ids = [module.redshift_sg.security_group_id]
  subnet_ids         = var.database_subnets

  enhanced_vpc_routing = true

  #  publicly_accessible = var.redshift_serverless_publicly_accessible

  tags = merge(local.all_tags,
    { Name = local.namespace_name }
  )

}
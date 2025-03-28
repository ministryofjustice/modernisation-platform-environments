
resource "aws_redshiftserverless_namespace" "default" {
  namespace_name = local.namespace_name
  manage_admin_password = true
  
  iam_roles = [
    aws_iam_role.redshift.arn, aws_iam_role.ycs-team.arn, aws_iam_role.yjb-moj-team.arn, aws_iam_role.yjb-team.arn
  ]

  kms_key_id = var.kms_key_arn
  
  tags = merge(local.all_tags,
      { Name        = local.namespace_name }
    )
}

# Create the Redshift Serverless Workgroup
resource "aws_redshiftserverless_workgroup" "default" {
  depends_on = [aws_redshiftserverless_namespace.default]

  namespace_name = aws_redshiftserverless_namespace.default.id
  workgroup_name = aws_redshiftserverless_namespace.default.id
 # base_capacity  = var.redshift_serverless_base_capacity
  
  security_group_ids = [ module.redshift_sg.security_group_id ]
  subnet_ids         = var.database_subnets
  
  #  publicly_accessible = var.redshift_serverless_publicly_accessible
  
  tags = merge(local.all_tags,
      { Name        = local.namespace_name }
    )

}
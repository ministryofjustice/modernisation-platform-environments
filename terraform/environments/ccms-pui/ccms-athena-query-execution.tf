resource "null_resource" "execute_create_table_queries" {
  triggers = {
    query_ids = join(",",["${aws_athena_named_query.main_table_pui.id}", "${aws_athena_named_query.http_requests_pui.id}"
    ])
  }

  provisioner "local-exec" {
    command = <<EOF
CREDS=$(aws sts assume-role --role-arn arn:aws:iam::${data.aws_caller_identity.current.id}:role/MemberInfrastructureAccess --role-session-name github-actions-session)
export AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDS | jq -r '.Credentials.SessionToken')
aws athena start-query-execution \
  --query-string "$(aws athena get-named-query --named-query-id ${aws_athena_named_query.main_table_pui.id} --query 'NamedQuery.QueryString' --output text)" \
  --work-group ${aws_athena_workgroup.lb-access-logs.name} \
  --query-execution-context Database=${aws_athena_database.lb-access-logs.name} \
  --region ${data.aws_region.current.name}
aws athena start-query-execution \
  --query-string "$(aws athena get-named-query --named-query-id ${aws_athena_named_query.http_requests_pui.id} --query 'NamedQuery.QueryString' --output text)" \
  --work-group ${aws_athena_workgroup.lb-access-logs.name} \
  --query-execution-context Database=${aws_athena_database.lb-access-logs.name} \
  --region ${data.aws_region.current.name}
EOF
  }

  depends_on = [
    aws_athena_named_query.main_table_pui,
    aws_athena_named_query.http_requests_pui,
    aws_athena_workgroup.lb-access-logs,
    aws_athena_database.lb-access-logs
  ]
}
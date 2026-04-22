# Execute the create table queries automatically after creation
resource "null_resource" "execute_create_ssogen_table_queries" {
  count = local.is-development || local.is-test ? 1 : 0
  triggers = {
    query_ids = join(",", ["${aws_athena_named_query.main_table_ssogen[count.index].id}", "${aws_athena_named_query.http_requests_ssogen[count.index].id}","${aws_athena_named_query.main_table_ssogen_console[count.index].id}", "${aws_athena_named_query.http_requests_ssogen_console[count.index].id}"])
  }

  provisioner "local-exec" {
    command = <<EOF
CREDS=$(aws sts assume-role --role-arn arn:aws:iam::${data.aws_caller_identity.current.id}:role/MemberInfrastructureAccess --role-session-name github-actions-session)
export AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDS | jq -r '.Credentials.SessionToken')
aws athena start-query-execution \
  --query-string "$(aws athena get-named-query --named-query-id ${aws_athena_named_query.main_table_ssogen[count.index].id} --query 'NamedQuery.QueryString' --output text)" \
  --work-group ${aws_athena_workgroup.ssogen_lb-access-logs[count.index].name} \
  --query-execution-context Database=${aws_athena_database.ssogen_lb-access-logs[count.index].name} \
  --region ${data.aws_region.current.name}
aws athena start-query-execution \
  --query-string "$(aws athena get-named-query --named-query-id ${aws_athena_named_query.main_table_ssogen_console[count.index].id} --query 'NamedQuery.QueryString' --output text)" \
  --work-group ${aws_athena_workgroup.ssogen_lb-access-logs[count.index].name} \
  --query-execution-context Database=${aws_athena_database.ssogen_lb-access-logs[count.index].name} \
  --region ${data.aws_region.current.name}
aws athena start-query-execution \
  --query-string "$(aws athena get-named-query --named-query-id ${aws_athena_named_query.http_requests_ssogen[count.index] .id} --query 'NamedQuery.QueryString' --output text)" \
  --work-group ${aws_athena_workgroup.ssogen_lb-access-logs[count.index].name} \
  --query-execution-context Database=${aws_athena_database.ssogen_lb-access-logs[count.index].name} \
  --region ${data.aws_region.current.name}
aws athena start-query-execution \
  --query-string "$(aws athena get-named-query --named-query-id ${aws_athena_named_query.http_requests_ssogen_console[count.index] .id} --query 'NamedQuery.QueryString' --output text)" \
  --work-group ${aws_athena_workgroup.ssogen_lb-access-logs[count.index].name} \
  --query-execution-context Database=${aws_athena_database.ssogen_lb-access-logs[count.index].name} \
  --region ${data.aws_region.current.name}
EOF
  }

  depends_on = [
    aws_athena_named_query.main_table_ssogen[0],
    aws_athena_named_query.http_requests_ssogen[0],
    aws_athena_named_query.main_table_ssogen_console[0],
    aws_athena_named_query.http_requests_ssogen_console[0],
    aws_athena_workgroup.ssogen_lb-access-logs[0],
    aws_athena_database.ssogen_lb-access-logs[0]
  ]
}
# Execute the create table queries automatically after creation
resource "null_resource" "execute_create_table_queries" {
  triggers = {
    query_ids = "${aws_athena_named_query.main_table_ebsapp_internal.id}"
  }

  provisioner "local-exec" {
    command = <<EOF
aws athena start-query-execution \
  --query-string "$(aws athena get-named-query --named-query-id ${aws_athena_named_query.main_table_ebsapp_internal.id} --query 'NamedQuery.QueryString' --output text)" \
  --work-group ${aws_athena_workgroup.lb-access-logs.name} \
  --query-execution-context Database=${aws_athena_database.lb-access-logs.name} \
  --region ${data.aws_region.current.name}
EOF
  }

  depends_on = [
    aws_athena_named_query.main_table_ebsapp_internal,
    aws_athena_workgroup.lb-access-logs,
    aws_athena_database.lb-access-logs
  ]
}
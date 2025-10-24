output "aws_athena_database_lb_access_logs_id" {
  description = "aws_athena_database lb-access-logs id"
  value       = aws_athena_database.lb-access-logs.id
}

output "aws_athena_workgroup_lb_access_logs_arn" {
  description = "aws_athena_workgroup lb-access-logs arn"
  value       = aws_athena_workgroup.lb-access-logs.arn
}

output "aws_athena_workgroup_lb_access_logs_configuration" {
  description = "aws_athena_workgroup lb-access-logs configuration"
  value       = aws_athena_workgroup.lb-access-logs.configuration
}

output "aws_athena_workgroup_lb_access_logs_id" {
  description = "aws_athena_workgroup lb-access-logs id"
  value       = aws_athena_workgroup.lb-access-logs.id
}

output "aws_athena_named_query_main_table_admin" {
  description = "aws_athena_named_query main_table_admin id"
  value       = aws_athena_named_query.main_table_admin.id
}

output "aws_athena_named_query_tls_requests_admin" {
  description = "aws_athena_named_query tls_requests_admin id"
  value       = aws_athena_named_query.tls_requests_admin.id
}

output "aws_athena_named_query_main_table_managed" {
  description = "aws_athena_named_query main_table_managed id"
  value       = aws_athena_named_query.main_table_managed.id
}

output "aws_athena_named_query_tls_requests_managed" {
  description = "aws_athena_named_query tls_requests_managed id"
  value       = aws_athena_named_query.tls_requests_managed.id
}

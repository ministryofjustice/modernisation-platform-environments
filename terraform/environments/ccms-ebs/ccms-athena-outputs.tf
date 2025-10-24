output "aws_athena_database_lb_access_logs_id" {
  description = "aws_athena_database lb-access-logs id"
  value       = aws_athena_database.lb-access-logs.id
}

#

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

#

output "aws_athena_named_query_main_table_ebsapp" {
  description = "aws_athena_named_query main_table_ebsapp id"
  value       = aws_athena_named_query.main_table_ebsapp.id
}

#

output "aws_athena_named_query_http_requests_ebsapp" {
  description = "aws_athena_named_query http_requests_ebsapp id"
  value       = aws_athena_named_query.http_requests_ebsapp.id
}

output "aws_athena_named_query_main_table_ebsapp_internal" {
  description = "aws_athena_named_query main_table_ebsapp_internal id"
  value       = aws_athena_named_query.main_table_ebsapp_internal.id
}

#

output "aws_athena_named_query_http_requests_ebsapp_internal" {
  description = "aws_athena_named_query http_requests_ebsapp_internal id"
  value       = aws_athena_named_query.http_requests_ebsapp_internal.id
}
#

# output "aws_athena_named_query_main_table_wgate" {
#   description = "aws_athena_named_query main_table_wgate id"
#   value       = aws_athena_named_query.main_table_wgate.id
# }

# #

# output "aws_athena_named_query_http_requests_wgate" {
#   description = "aws_athena_named_query http_requests_wgate id"
#   value       = aws_athena_named_query.http_requests_wgate.id
# }

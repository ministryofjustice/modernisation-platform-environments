# Temporary: moves the already-applied Athena resources into module.athena_lb_logs without recreating them.
# Delete this file once the change has been applied.

moved {
  from = aws_glue_catalog_database.lb_access_logs
  to   = module.athena_lb_logs.aws_glue_catalog_database.this
}

moved {
  from = aws_athena_workgroup.lb_access_logs
  to   = module.athena_lb_logs.aws_athena_workgroup.this
}

moved {
  from = aws_glue_catalog_table.alb_access_logs
  to   = module.athena_lb_logs.aws_glue_catalog_table.this["alb"]
}

moved {
  from = aws_glue_catalog_table.nlb_access_logs
  to   = module.athena_lb_logs.aws_glue_catalog_table.this["nlb"]
}

moved {
  from = aws_athena_named_query.alb_errors_last_day
  to   = module.athena_lb_logs.aws_athena_named_query.this["alb_errors_last_day"]
}

moved {
  from = aws_athena_named_query.alb_slowest_requests_last_day
  to   = module.athena_lb_logs.aws_athena_named_query.this["alb_slowest_requests_last_day"]
}

moved {
  from = aws_athena_named_query.alb_requests_by_client_last_day
  to   = module.athena_lb_logs.aws_athena_named_query.this["alb_requests_by_client_last_day"]
}

moved {
  from = aws_athena_named_query.nlb_connections_last_day
  to   = module.athena_lb_logs.aws_athena_named_query.this["nlb_connections_last_day"]
}

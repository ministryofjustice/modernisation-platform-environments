# name - (Required) The name of the query.
# query_string - (Required) The query to save. You can read more about CloudWatch Logs Query Syntax in the documentation.
# log_group_names - (Optional) Specific log groups to use with the query.

resource "aws_cloudwatch_query_definition" "this" {
  count = var.create_cw_insight ? 1 : 0

  name            = var.query_name
  log_group_names = var.log_groups
  query_string    = var.query
}
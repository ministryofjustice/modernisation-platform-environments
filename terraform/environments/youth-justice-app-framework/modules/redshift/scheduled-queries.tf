resource "aws_redshiftserverless_scheduled_query" "refresh_yjb_case_reporting_mvs" {
  name          = "QS2-refresh-yjb-case-reporting-materialized-views"
  description   = "Refreshes all Materialized views in the yjb_case_reporting_schema"
  query_string  = "CALL yjb_ianda_team.refresh_materialized_views();"

  #daily at 5am UTC
  schedule          = "cron(0 5 * * ? *)"
  workgroup_name    = aws_redshiftserverless_workgroup.default.workgroup_name
  role_arn          = aws_iam_role.yjb-moj-team.arn

  authentication {
    secret_arn = aws_secretsmanager_secret.yjb_schedular.arn
  }
}


resource "aws_redshiftserverless_scheduled_query" "fte_redshift" {
  name        = "QS2-fte_redshift"
  description = "Rebuilds the yjb_ianda_team.fte_redshift view once a week"
  query_string = file("${path.module}/scripts/fte_redshift.sql")

  #Mondays at 08:30 UTC
  schedule          = "cron(30 8 ? * MON *)"
  workgroup_name    = aws_redshiftserverless_workgroup.default.workgroup_name
  role_arn          = aws_iam_role.yjb-moj-team.arn

  authentication {
    secret_arn = aws_secretsmanager_secret.yjb_schedular.arn
  }
}

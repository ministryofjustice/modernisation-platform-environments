moved {
  from = aws_ssm_parameter.aws_health_lambda_accounts[0]
  to   = aws_ssm_parameter.aws_health_lambda["accounts"]
}

moved {
  from = aws_ssm_parameter.aws_health_lambda_ignore_findings[0]
  to   = aws_ssm_parameter.aws_health_lambda["ignore_findings"]
}

moved {
  from = aws_ssm_parameter.aws_health_lambda_github_project_number[0]
  to   = aws_ssm_parameter.aws_health_lambda["github_project_number"]
}

resource "aws_sfn_state_machine" "csv_to_parquet_export" {
  name     = "${var.name}-csv-to-parquet-export" # fix the praquet typo
  role_arn = aws_iam_role.state_machine.arn

  definition = templatefile("${path.module}/state_machine.asl.json.tpl", {
    lambda_arn = module.csv-to-parquet-export.lambda_function_arn
  })
}

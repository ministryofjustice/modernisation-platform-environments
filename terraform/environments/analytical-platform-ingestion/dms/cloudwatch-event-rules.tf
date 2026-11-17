resource "aws_cloudwatch_event_rule" "metadata_generator" {
  name                = "metadata-generator"
  schedule_expression = "cron(0 0 * * ? *)" # midnight every day
}

# Tariff dev Oracle (Modernisation Platform) is shut down 21:00-06:00, so dev runs after it starts
resource "aws_cloudwatch_event_rule" "tariff_metadata_generator" {
  name                = "tariff-metadata-generator"
  schedule_expression = local.environment == "development" ? "cron(15 6 * * ? *)" : "cron(0 0 * * ? *)"
}

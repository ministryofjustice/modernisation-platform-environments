data "aws_sns_topic" "pagerduty" {
  for_each = toset(["high-priority", "low-priority"])

  name = "pagerduty-${each.key}"
}

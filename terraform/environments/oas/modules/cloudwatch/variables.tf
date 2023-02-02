/* variable "cloudwatch_metric_alarms" {
  type = map(object({
		add_to_dashboard    = bool
    alarm_name          = string
    alarm_description   = string
    comparison_operator = string
    evaluation_periods  = string
    metric_name         = string
    namespace           = string
    period              = string
    statistic           = string
    threshold           = string
    alarm_actions       = string
    ok_actions          = string
    treat_missing_data  = string
  }))
} */

variable "aws_region" {
  default = "eu-west-2"
}

variable "dashboard_widget_refresh_period" {
  default = 60
}

variable "cloudwatch_metric_alarms" {}

variable "dashboard_name" {}

variable "snsTopicName" {
  description = "Name of the SNS Topic"
  type        = string

}

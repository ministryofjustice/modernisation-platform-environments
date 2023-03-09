variable "topic" {
  type        = string
  description = "ARN of SNS topic to send alerts to"
}
variable "name" {
  type        = string
  description = "name of the instance"
}
variable "instanceIds" {
  type        = string
  description = "instanceIds to monitor"
}
variable "metric" {
  type        = string
  description = "metric to be reported on"
}

variable "eval_periods" {
  type        = string
  description = "how many periods over which to evaluate the alarm"
}
#how many datapoints must be breaching the threshold to trigger the alarm
variable "period" {
  type        = string
  description = "period in seconds over which the specified statistic is applied"
}
variable "threshold" {
  type        = string
  description = "threshold for the alarm"
}

variable "instanceId" {
  type        = string
  description = "the instanceId for the alarm"
}
variable "imageId" {
  type        = string
  description = "the imageId for the alarm"
}
variable "instanceType" {
  type        = string
  description = "the instanceType for the alarm"
}
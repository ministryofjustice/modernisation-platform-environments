variable "topic" {
  type        = string
  description = "ARN of SNS topic to send alerts to"
}
variable "name" {
  type        = string
  description = "name of the instance"
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
variable "rootDevice" {
  type        = string
  description = "the rootDevice for the alarm"
}
variable "fileSystem" {
  type        = string
  description = "the fileSystem for the alarm"
}
###################
variable "cpu_eval_periods"{
  type        = string
  description = "how many periods over which to evaluate the alarm"
}
variable "cpu_datapoints"{
  type        = string
  description = "how many data points over which the specified statistic is applied"
}
variable "cpu_period"{
  type        = string
  description = "period in seconds over which the specified statistic is applied"
}
variable "cpu_threshold"{
  type        = string
  description = "threshold for the alarm"
}
variable "mem_eval_periods"{
  type        = string
  description = "how many periods over which to evaluate the alarm"
}
variable "mem_datapoints"{
  type        = string
  description = "how many data points over which the specified statistic is applied"
}
variable "mem_period"{
  type        = string
  description = "period in seconds over which the specified statistic is applied"
}
variable "mem_threshold"{
  type        = string
  description = "threshold for the alarm"
}
variable "disk_eval_periods"{
  type        = string
  description = "how many periods over which to evaluate the alarm"
}
variable "disk_datapoints"{
  type        = string
  description = "how many data points over which the specified statistic is applied"
}
variable "disk_period"{
  type        = string
  description = "period in seconds over which the specified statistic is applied"
}
variable "disk_threshold"{
  type        = string
  description = "threshold for the alarm"
}
variable "insthc_eval_periods"{
  type        = string
  description = "how many periods over which to evaluate the alarm"
}
variable "insthc_period"{
  type        = string
  description = "period in seconds over which the specified statistic is applied"
}
variable "insthc_threshold"{
  type        = string
  description = "threshold for the alarm"
}
variable "syshc_eval_periods"{
  type        = string
  description = "how many periods over which to evaluate the alarm"
}
variable "syshc_period"{
  type        = string
  description = "period in seconds over which the specified statistic is applied"
}
variable "syshc_threshold"{
  type        = string
  description = "threshold for the alarm"
}

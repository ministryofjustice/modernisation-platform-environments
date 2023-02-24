variable "region" {
  default = "eu-west-2"

}
variable "pClusterName" {
  type    = string
  default = ""
}
variable "pAutoscalingGroupName" {
  type    = string
  default = ""

}
variable "pLoadBalancerName" {
  type    = string
  default = ""

}
variable "pTargetGroupName" {
  type    = string
  default = ""

}
variable "appnameenv" {
  default = ""

}

variable "pECSCPUAlarmThreshold" {
  description = "ECS CPU Alarm Threshold"
  type        = number
  default     = "75"
}
variable "pECSMemoryAlarmThreshold" {
  description = "ECS Meomry Alarm Threshold"
  type        = number
  default     = "75"
}
variable "pASGCPUAlarmThreshold" {
  description = "ASG CPU Alarm Threshold"
  type        = number
  default     = "85"
}
variable "pASGStatusFailureAlarmThreshold" {
  description = "ASG Status Check Failures Alarm Threshold"
  type        = number
  default     = "1"
}
variable "pALBUnhealthyAlarmThreshold" {
  description = "ALB Unhealthy Hosts Alarm Threshold"
  type        = number
  default     = "0"
}
variable "pALBRejectedAlarmThreshold" {
  description = "ALB Rejected Requests Alarm Threshold"
  type        = number
  default     = "10"
}
variable "pALB5xxAlarmThreshold" {
  description = "ALB Originiating 5xx Alarm Threshold"
  type        = number
  default     = "10"
}
variable "pALBTarget5xxAlarmThreshold" {
  description = "ALB Target Originiating 5xx Alarm Threshold"
  type        = number
  default     = "10"
}
variable "pALB4xxAlarmThreshold" {
  description = "ALB Originiating 4xx Alarm Threshold"
  type        = number
  default     = "10"
}
variable "pALBTarget4xxAlarmThreshold" {
  description = "ALB Target Originiating 4xx Alarm Threshold"
  type        = number
  default     = "10"
}
variable "pALBTargetResponseTimeThreshold" {
  description = "ALB Target Response Time Alarm Threshold"
  type        = number
  default     = "10"
}
variable "pALBTargetResponseTimeThresholdMaximum" {
  description = "ALB Target Response Time Alarm Threshold Maximum"
  type        = number
  default     = "60"
}

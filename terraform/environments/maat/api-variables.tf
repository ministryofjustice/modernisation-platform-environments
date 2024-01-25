variable "ecs_cpu_alarm_threshold" {
  type    = number
  default = 75
}
variable "ecs_memory_alarm_threshold" {
  type    = number
  default = 75
}
variable "alb_target_response_time_threshold" {
  type    = number
  default = 10
}
variable "alb_target_response_time_threshold_maximum" {
  type    = number
  default = 60
}
variable "alb_unhealthy_alarm_threshold" {
  type    = number
  default = 0
}
variable "alb_rejected_alarm_threshold" {
  type    = number
  default = 10
}
variable "alb_target_5xx_alarm_threshold" {
  type    = number
  default = 10
}
variable "alb_5xx_alarm_threshold" {
  type    = number
  default = 10
}
variable "alb_target_4xx_alarm_threshold" {
  type    = number
  default = 10
}
variable "alb_4xx_alarm_threshold" {
  type    = number
  default = 10
}
variable "ecs_high_cpu_scaling_threshold" {
  type    = number
  default = 70
}
variable "ecs_low_cpu_scaling_threshold" {
  type    = number
  default = 20
}
variable "ecs_high_memory_scaling_threshold" {
  type    = number
  default = 70
}
variable "ecs_low_memory_scaling_threshold" {
  type    = number
  default = 20
}
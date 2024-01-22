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
#------------------------------------------------------------------------------
# Schedule stop/start EC2 instances
#------------------------------------------------------------------------------

module "stop_ec2_instance_nights" {
  source                         = "github.com/diodonfrost/terraform-aws-lambda-scheduler-stop-start?ref=3.1.3"
  name                           = "stop_ec2_instance_nights"
  cloudwatch_schedule_expression = "cron(0/5 * * * ? *)" # "cron(0 0 ? * FRI *)" # Every Friday at 23:00 GMT
  schedule_action                = "stop"
  autoscaling_schedule           = "false"
  ec2_schedule                   = "true"
  rds_schedule                   = "false"
  cloudwatch_alarm_schedule      = "false"
  scheduler_tag = {
    key   = "stop_nights"
    value = "ec2"
  }
}

module "start_ec2_instance_mornings" {
  source                         = "github.com/diodonfrost/terraform-aws-lambda-scheduler-stop-start?ref=3.1.3"
  name                           = "start_ec2_instance_mornings"
  cloudwatch_schedule_expression = "cron(0/3 * * * ? *)" # "cron(0 8 ? * MON *)" # Every Monday at 8:00 GMT
  schedule_action                = "start"
  autoscaling_schedule           = "false"
  ec2_schedule                   = "true"
  rds_schedule                   = "false"
  cloudwatch_alarm_schedule      = "false"
  scheduler_tag = {
    key   = "stop_nights"
    value = "ec2"
  }
}
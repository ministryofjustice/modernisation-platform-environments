module "cwalarm_1" {
    source = "./modules/cloudwatch-alarms"

    alarmname = "elb-4xx-error-alarm"
    oper      = "GreaterThanThreshold"
    eval      = "5"
    metricname = "HTTPCode_ELB_4XX_Count"
    namespace  = "AWS/ApplicationELB"
    period     = "60"
    stat       = "Sum"
    thresh     = "10"
    alarmdesc  = "This alarm will trigger if we receive 4 4XX elb alerts in a 5 minute period."

  
}
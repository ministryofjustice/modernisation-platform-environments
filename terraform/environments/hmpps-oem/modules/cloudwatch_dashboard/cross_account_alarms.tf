resource "aws_cloudwatch_metric_alarm" "oasys-cpu-util" {
    alarm_name = "oasys-cpu-util"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = "15"
    datapoints_to_alarm = "15"
    threshold           = "95"
    alarm_description   = "Triggers if the average cpu remains at 95% utilization or above for 15 minutes. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4326064583"

    metric_query {
        id = "m1"
        account_id = "612659970365"
        return_data = "true"
        metric {
            metric_name = "CPUUtilization"
            namespace = "AWS/EC2"
            period = "60"
            stat = "Maximum"
        }
    }
}

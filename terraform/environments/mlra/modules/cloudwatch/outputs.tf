output "esccpuoverthreshold" {
  description = "Output arn for the alarm"
  value       = aws_cloudwatch_metric_alarm.esccpuoverthreshold.arn

}
output "ecsmemoryoverthreshold" {
  description = "Output arn for the alarm"
  value       = aws_cloudwatch_metric_alarm.ecsmemoryoverthreshold.arn

}
output "cpuoverthreshold" {
  description = "Output arn for the alarm"
  value       = aws_cloudwatch_metric_alarm.cpuoverthreshold.arn

}
output "statuscheckfailure" {
  description = "Output arn for the alarm"
  value       = aws_cloudwatch_metric_alarm.statuscheckfailure.arn

}
output "targetresponsetime" {
  description = "Output arn for the alarm"
  value       = aws_cloudwatch_metric_alarm.targetresponsetime.arn

}
output "targetResponsetimemaximum" {
  description = "Output arn for the alarm"
  value       = aws_cloudwatch_metric_alarm.targetResponsetimemaximum.arn

}
output "unhealthyhosts" {
  description = "Output arn for the alarm"
  value       = aws_cloudwatch_metric_alarm.unhealthyhosts.arn

}
output "rejectedconnectioncount" {
  description = "Output arn for the alarm"
  value       = aws_cloudwatch_metric_alarm.rejectedconnectioncount.arn

}
output "http5xxerror" {
  description = "Output arn for the alarm"
  value       = aws_cloudwatch_metric_alarm.http5xxerror.arn

}
output "applicationelb5xxerror" {
  description = "Output arn for the alarm"
  value       = aws_cloudwatch_metric_alarm.applicationelb5xxerror.arn

}
output "http4xxerror" {
  description = "Output arn for the alarm"
  value       = aws_cloudwatch_metric_alarm.http4xxerror.arn

}
output "applicationelb4xxerror" {
  description = "Output arn for the alarm"
  value       = aws_cloudwatch_metric_alarm.applicationelb4xxerror.arn

}
output "sns_topic_name" {
  description = "Output SNS topic name to establish dependency between this module and pagerduty_core_alerts module"
  value       = aws_sns_topic.mlra_alerting_topic.id
}

resource "aws_cloudwatch_dashboard" "mlra" {
  dashboard_name = local.application_name

  dashboard_body = <<EOF
{
  "widgets": [
    {
      "type": "${var.cloudwatch_type}",
      "x": 0,
      "y": 0,
      "width": 8,
      "height": 6,
      "properties": {
        "period": "${var.cloudwatch_dashboard_period}",
        "stat": "${var.cloudwatch_stat}",
        "region": "${local.application_data.accounts[local.environment].region}"
        "annotations": {
          "alarms": module.cloudwatch-alarm.applicationelb5xxerror.value
        }, 
        "view": "${var.cloudwatch_view}"
        "stacked": "${var.cloudwatch_stacked}",
        "title": "${var.cloudwatch_dashboard_title}"
      }
    },
  ]
},
{
      "type": "${var.cloudwatch_type}",
      "x": 8,
      "y": 0,
      "width": 8,
      "height": 6,
      "properties": {
        "period": "${var.cloudwatch_dashboard_period}",
        "stat": "${var.cloudwatch_stat}",
        "annotations": {
          "alarms": module.cloudwatch-alarm.applicationelb4xxerror.value
        }, 
        "region": "${local.application_data.accounts[local.environment].region}",
        "view": "${var.cloudwatch_view}",
        "stacked": "${var.cloudwatch_stacked}",
        "title": "${var.cloudwatch_dashboard_title}"
      }
    },
    {
      "type": "${var.cloudwatch_type}",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "period": "${var.cloudwatch_dashboard_period}",
        "stat": "${var.cloudwatch_stat}",
        "annotations": {
          "alarms": module.cloudwatch-alarm.targetresponsetime.value
        }, 
        "region": "${local.application_data.accounts[local.environment].region}",
        "view": "${var.cloudwatch_view}",
        "stacked": "${var.cloudwatch_stacked}",
        "title": "${var.cloudwatch_dashboard_title}"
      },
      {
      "type": "${var.cloudwatch_type}",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "period": "${var.cloudwatch_dashboard_period}",
        "stat": "${var.cloudwatch_stat}",
        "annotations": {
          "alarms": module.cloudwatch-alarm.esccpuoverthreshold.value
        }, 
        "region": "${local.application_data.accounts[local.environment].region}}",
        "view": "${var.cloudwatch_view}",
        "stacked": "${var.cloudwatch_stacked}",
        "title": "${var.cloudwatch_dashboard_title}"
      }
    },
    {
      "type": "${var.cloudwatch_type}",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
  
        ],
        "period": "${var.cloudwatch_dashboard_period}",
        "stat": "${var.cloudwatch_stat}",
        "annotations": {
          "alarms": module.cloudwatch-alarm.ecsmemoryoverthreshold.value
        } ,
        "region": "${local.application_data.accounts[local.environment].region}",
        "view": "${var.cloudwatch_view}",
        "stacked": "${var.cloudwatch_stacked}",
        "title": "${var.cloudwatch_dashboard_title}"
      }
    }
    
  ]
}
EOF
}


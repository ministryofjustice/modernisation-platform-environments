resource "aws_cloudwatch_dashboard" "mlra" {
  dashboard_name = local.application_name

  dashboard_body = <<EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 8,
      "height": 6,
      "properties": {
        "period": 60,
        "stat": "Average",
        "region": "${local.application_data.accounts[local.environment].region}"
        "annotations": {
          "alarms": #[module.<marks_module>.<output_name]
        }, 
        "view": "timeSeries"
        "stacked": "false",
        "title": "Application ELB 5xx Error"
      }
    },
  ]
},
{
      "type": "metric",
      "x": 8,
      "y": 0,
      "width": 8,
      "height": 6,
      "properties": {
        "period": 60,
        "stat": "Average",
        "annotations": {
          "alarms": #[module.<marks_module>.<output_name]
        }, 
        "region": "${local.application_data.accounts[local.environment].region}",
        "view": "timeSeries",
        "stacked": "false",
        "title": "Application ELB 4xx Error"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "period": 300,
        "stat": "Average",
        "annotations": {
          "alarms": #[module.<marks_module>.<output_name]
        }, 
        "region": "${local.application_data.accounts[local.environment].region}",
        "view": "timeSeries",
        "stacked": "false",
        "title": "Application ELB Target Response Time"
      },
      {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "period": 300,
        "stat": "Average",
        "annotations": {
          "alarms": #[module.<marks_module>.<output_name]
        }, 
        "region": "${local.application_data.accounts[local.environment].region}}",
        "view": "timeSeries",
        "stacked": "false",
        "title": "EC2 CPU"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
  
        ],
        "period": 300,
        "stat": "Average",
        "annotations": {
          "alarms": #[module.<marks_module>.<output_name]
        } ,
        "region": "${local.application_data.accounts[local.environment].region}",
        "view": "timeSeries",
        "stacked": "false",
        "title": "ECS Memory"
      }
    }
    
  ]
}
EOF
}  


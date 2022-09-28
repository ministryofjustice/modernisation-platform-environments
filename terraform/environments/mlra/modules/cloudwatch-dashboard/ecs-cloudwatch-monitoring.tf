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
        "period": 60,
        "stat": "${var.cloudwatch_stat}",
        "region": "${local.application_data.accounts[local.environment].region}"
        "annotations": {
          "alarms": #[module.<marks_module>.<output_name]
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
        "period": 60,
        "stat": "${var.cloudwatch_stat}",
        "annotations": {
          "alarms": #[module.<marks_module>.<output_name]
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
        "period": 300,
        "stat": "${var.cloudwatch_stat}",
        "annotations": {
          "alarms": #[module.<marks_module>.<output_name]
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
        "period": 300,
        "stat": "${var.cloudwatch_stat}",
        "annotations": {
          "alarms": #[module.<marks_module>.<output_name]
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
        "period": 300,
        "stat": "${var.cloudwatch_stat}",
        "annotations": {
          "alarms": #[module.<marks_module>.<output_name]
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


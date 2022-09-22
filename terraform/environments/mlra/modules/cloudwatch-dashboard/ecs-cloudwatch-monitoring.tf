resource "aws_cloudwatch_dashboard" "mlra" {
  dashboard_name = var.application_name

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
        "metrics": [
          [
          
            "AWS/EC2",
            "CPUUtilization",
            "InstanceId",
            "i-012345"
          ]
        ],
        "period": 60,
        "stat": "Average",
        "region": "${var.aws_region}"
        "annotations": {
          "alarms": ["arn:aws:cloudwatch:${AWS::Region}:${AWS::AccountId}:alarm:${ApplicationELB5xxError}"]
        } 
        "view": "timeSeries"
        "stacked": false
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
        "metrics": [
          [
          
            "AWS/EC2",
            "CPUUtilization",
            "InstanceId",
            "i-012345"
          ]
        ],
        "period": 60,
        "stat": "Average",
        "region": "${var.aws_region}",
        "view": "timeSeries"
        "stacked": false
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
        "metrics": [
          [
            "AWS/EC2",
            "CPUUtilization",
            "InstanceId",
            "i-012345"
          ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "${var.aws_region}",
        "view": "timeSeries"
        "stacked": false
        "title": "Application ELB Target Response Time"
      },
      {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "AWS/EC2",
            "CPUUtilization",
            "InstanceId",
            "i-012345"
          ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "${var.aws_region}",
        "view": "timeSeries"
        "stacked": false
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
          [
            "AWS/EC2",
            "CPUUtilization",
            "InstanceId",
            "i-012345"
          ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "${var.aws_region}",
        "view": "timeSeries"
        "stacked": false
        "title": "ECS Memory"
      }
    }
    
  ]
}
EOF
}
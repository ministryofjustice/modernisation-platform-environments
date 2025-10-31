{
  "periodOverride": "inherit",
  "widgets": [
          {
                  "type": "metric",
                  "x": 0,
                  "y": 0,
                  "height": 5,
                  "width": 8,
                  "properties": {
                          "title": "EC2 CPU Usage",
                          "annotations": {
                                  "alarms": [
                                          "${cpu_alarm_arn}"
                                  ]
                          },
                          "view": "timeSeries",
                          "legend": {
                                  "position": "hidden"
                          },
                          "period": ${dashboard_widget_refresh_period},
                          "region": "${aws_region}",
                          "stacked": true
                  }
          },
          {
                  "type": "metric",
                  "x": 8,
                  "y": 0,
                  "height": 5,
                  "width": 8,
                  "properties": {
                          "title": "EC2 Memory Usage",
                          "annotations": {
                                  "alarms": [
                                          "${memory_alarm_arn}"
                                  ]
                          },
                          "view": "timeSeries",
                          "legend": {
                                  "position": "hidden"
                          },
                          "period": ${dashboard_widget_refresh_period},
                          "region": "${aws_region}",
                          "stacked": true
                  }
          },
          {
                  "type": "metric",
                  "x": 0,
                  "y": 1,
                  "height": 5,
                  "width": 8,
                  "properties": {
                          "title": "Root EBS Disk Usage",
                          "annotations": {
                                  "alarms": [
                                          "${ebs_root_volume_alarm_arn}"
                                  ]
                          },
                          "view": "timeSeries",
                          "legend": {
                                  "position": "hidden"
                          },
                          "period": ${dashboard_widget_refresh_period},
                          "region": "${aws_region}",
                          "stacked": true
                  }
          },
          {
                  "type": "metric",
                  "x": 8,
                  "y": 1,
                  "height": 5,
                  "width": 8,
                  "properties": {
                          "title": "EBS Disk Usage",
                          "annotations": {
                                  "alarms": [
                                          "${ebs_volume_alarm_arn}"
                                  ]
                          },
                          "view": "timeSeries",
                          "legend": {
                                  "position": "hidden"
                          },
                          "period": ${dashboard_widget_refresh_period},
                          "region": "${aws_region}",
                          "stacked": true
                  }
          },
          {
                  "type": "alarm",
                  "x": 0,
                  "y": 2,
                  "width": 8,
                  "height": 5,
                  "properties": {
                          "title": "Resource Consumption Alarms",
                          "alarms": [
                                  "${cpu_alarm_arn}",
                                  "${memory_alarm_arn}",
                                  "${ebs_root_volume_alarm_arn}",
                                  "${ebs_volume_alarm_arn}"
                          ]
                  }
          }
  ]
}

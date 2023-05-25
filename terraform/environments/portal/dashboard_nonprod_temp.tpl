{
          "widgets" : [
              {
                "type" : "metric",
                "x" : 0,
                "y" : 12,
                "width" : 8,
                "height" : 6,
                "properties" : {
                    "title" : "OAM1 Memory usage",
                    "annotations": {
                      "alarms": [
                        "${oam1_memory_alarm_arn}"
                      ]
                    },
                    "view": "timeSeries",
                    "region": "${aws_region}",
                    "stacked": false
                }
              },
              {
                "type" : "metric",
                "x" : 8,
                "y" : 12,
                "width" : 8,
                "height" : 6,
                "properties" : {
                    "title" : "OHS1 Memory usage",
                    "annotations": {
                      "alarms": [
                        "${ohs1_memory_alarm_arn}"
                      ]
                    },
                    "view": "timeSeries",
                    "region": "${aws_region}",
                    "stacked": false
                }
              }
          ]
}

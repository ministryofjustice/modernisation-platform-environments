{
          "widgets" : [
            {
              "type" : "metric",
              "x" : 0,
              "y" : 0,
              "width" : 8,
              "height" : 6,
              "properties" : {
                  "title" : "Application ELB 5xx Error",
                  "annotations": {
                    "alarms": [
                      "${alb_elb_5xx_alarm}"
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
              "y" : 0,
              "width" : 8,
              "height" : 6,
              "properties" : {
                  "title" : "Application ELB 4xx Error",
                  "annotations": {
                    "alarms": [
                      "${alb_elb_4xx_alarm}"
                    ]
                  },
                  "view": "timeSeries",
                  "region": "${aws_region}",
                  "stacked": false
              }
            },
            {
              "type" : "metric",
              "x" : 16,
              "y" : 0,
              "width" : 8,
              "height" : 6,
              "properties" : {
                  "title" : "Application ELB Target Response Time",
                  "annotations": {
                    "alarms": [
                      "${alb_response_time_alarm}"
                    ]
                  },
                  "view": "timeSeries",
                  "region": "${aws_region}",
                  "stacked": false
              }
            },
            {
              "type" : "metric",
              "x" : 0,
              "y" : 12,
              "width" : 12,
              "height" : 6,
              "properties" : {
                  "title" : "ECS CPU",
                  "annotations": {
                    "alarms": [
                      "${ecs_cpu_alarm}"
                    ]
                  },
                  "view": "timeSeries",
                  "region": "${aws_region}",
                  "stacked": false
              }
            },
            {
              "type" : "metric",
              "x" : 12,
              "y" : 12,
              "width" : 12,
              "height" : 6,
              "properties" : {
                  "title" : "ECS Memory",
                  "annotations": {
                    "alarms": [
                      "${ecs_memory_alarm}"
                    ]
                  },
                  "view": "timeSeries",
                  "region": "${aws_region}",
                  "stacked": false
              }
            }
          ]
}
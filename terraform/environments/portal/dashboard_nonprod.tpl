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
                      "${elb_5xx_alarm_arn}"
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
                      "${elb_4xx_alarm_arn}"
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
                      "${elb_response_time_alarm_arn}"
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
              "y" : 6,
              "width" : 8,
              "height" : 6,
              "properties" : {
                  "title" : "IADB RDS CPU",
                  "annotations": {
                    "alarms": [
                      "${iadb_cpu_alarm_arn}"
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
              "y" : 6,
              "width" : 8,
              "height" : 6,
              "properties" : {
                  "title" : "IADB RDS Read Lataency",
                  "annotations": {
                    "alarms": [
                      "${iadb_read_latency_alarm_arn}"
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
              "y" : 6,
              "width" : 8,
              "height" : 6,
              "properties" : {
                  "title" : "IADB RDS Write Latency",
                  "annotations": {
                    "alarms": [
                      "${iadb_write_latency_alarm_arn}"
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
              "width" : 8,
              "height" : 6,
              "properties" : {
                  "title" : "IGDB RDS CPU",
                  "annotations": {
                    "alarms": [
                      "${igdb_cpu_alarm_arn}"
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
                  "title" : "IGDB RDS Read Lataency",
                  "annotations": {
                    "alarms": [
                      "${igdb_read_latency_alarm_arn}"
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
              "y" : 12,
              "width" : 8,
              "height" : 6,
              "properties" : {
                  "title" : "IGDB RDS Write Latency",
                  "annotations": {
                    "alarms": [
                      "${igdb_write_latency_alarm_arn}"
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
              "width" : 8,
              "height" : 6,
              "properties" : {
                  "title" : "OIM1 CPU",
                  "annotations": {
                    "alarms": [
                      "${oim1_cpu_alarm_arn}"
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
                  "title" : "OIM1 Memory usage",
                  "annotations": {
                    "alarms": [
                      "${oim1_memory_alarm_arn}"
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
              "x" : 16,
              "y" : 12,
              "width" : 8,
              "height" : 6,
              "properties" : {
                  "title" : "IDM1 Memory usage",
                  "annotations": {
                    "alarms": [
                      "${idm1_memory_alarm_arn}"
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

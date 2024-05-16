{
        "periodOverride": "inherit",
        "widgets": [
                {
                        "type": "metric",
                        "x": 0,
                        "y": 0,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EC2 CPU Usage",
                                "annotations": {
                                        "alarms": [
                                                "${database_cpu_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                        "period": "${dashboard_refresh_period}",
                        "region": "${aws_region}",
                        "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 0,
                        "y": 2,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EC2 Network IO (Average Packet Count)",
                                "metrics": [
                                        [ "AWS/EC2", "NetworkPacketsIn", "InstanceId", "${database_instance_id}"],
                                        [ ".", "NetworkPacketsOut", ".", "." ]
                                ],
                                "view": "timeSeries",
                                "legend": {
                                        "position": "bottom"
                                },
                                "period": "${dashboard_refresh_period}",
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 12,
                        "y": 6,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Database Status Check Failed",
                                "annotations": {
                                        "alarms": [
                                                "${database_status_check_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": "${dashboard_refresh_period}",
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 18,
                        "y": 30,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Concurrent Manager Status Check Failed",
                                "annotations": {
                                        "alarms": [
                                                "cm_status_check_alarm"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": "${dashboard_refresh_period}",
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 18,
                        "y": 34,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "App Server 1 Status Check Failed",
                                "annotations": {
                                        "alarms": [
                                                "app1_status_check_alarm"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": "${dashboard_refresh_period}",
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 6,
                        "y": 7,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "ELB - Request Count",
                                "annotations": {
                                        "alarms": [
                                                "${elb_request_count_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": "${dashboard_refresh_period}",
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 6,
                        "y": 8,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EFS - Data Read IO Bytes",
                                "annotations": {
                                        "alarms": [
                                                "${efs_data_read_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": "${dashboard_refresh_period}",
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 12,
                        "y": 8,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EFS - Data Write IO Bytes",
                                "annotations": {
                                        "alarms": [
                                                "${efs_data_write_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": "${dashboard_refresh_period}",
                                "region": "${aws_region}",
                                "stacked": true
                        }
                }
        ]
}
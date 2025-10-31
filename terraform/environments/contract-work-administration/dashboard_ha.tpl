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
                        "period": ${dashboard_refresh_period},
                        "region": "${aws_region}",
                        "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 0,
                        "y": 1,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EC2 Memory Usage",
                                "annotations": {
                                        "alarms": [
                                                "${database_memory_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 6,
                        "y": 0,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EBS Disk Usage - Oradata",
                                "annotations": {
                                        "alarms": [
                                                "${database_oradata_diskspace_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 6,
                        "y": 1,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EBS Disk Usage - Oraarch",
                                "annotations": {
                                        "alarms": [
                                                "${database_oraarch_diskspace_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 6,
                        "y": 2,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EBS Disk Usage - Oratmp",
                                "annotations": {
                                        "alarms": [
                                                "${database_oratmp_diskspace_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 6,
                        "y": 3,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EBS Disk Usage - Oraredo",
                                "annotations": {
                                        "alarms": [
                                                "${database_oraredo_diskspace_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 6,
                        "y": 4,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EBS Disk Usage - Oracle",
                                "annotations": {
                                        "alarms": [
                                                "${database_oracle_diskspace_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 6,
                        "y": 5,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EBS Disk Usage - Root",
                                "annotations": {
                                        "alarms": [
                                                "${database_root_diskspace_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
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
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 0,
                        "y": 3,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EC2 RX Packets Dropped",
                                "annotations": {
                                        "alarms": [
                                                "${database_rx_packet_dropped_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": false
                        }
                },
                {
                        "type": "metric",
                        "x": 0,
                        "y": 4,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EC2 TX Packets Dropped",
                                "annotations": {
                                        "alarms": [
                                                "${database_tx_packet_dropped_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": false
                        }
                },
                {
                        "type": "metric",
                        "x": 0,
                        "y": 5,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EC2 RX Packet Errors",
                                "annotations": {
                                        "alarms": [
                                                "${database_rx_packet_errors_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": false
                        }
                },
                {
                        "type": "metric",
                        "x": 0,
                        "y": 6,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EC2 TX Packet Errors",
                                "annotations": {
                                        "alarms": [
                                                "${database_tx_packet_errors_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": false
                        }
                },
                {
                        "type": "metric",
                        "x": 12,
                        "y": 0,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Read Ops - Oradata",
                                "annotations": {
                                        "alarms": [
                                                "${database_oradata_read_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 12,
                        "y": 1,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Read Ops - Oraarch",
                                "annotations": {
                                        "alarms": [
                                                "${database_oraarch_read_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 12,
                        "y": 2,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Read Ops - Oratmp",
                                "annotations": {
                                        "alarms": [
                                                "${database_oratmp_read_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 12,
                        "y": 3,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Read Ops - Oraredo",
                                "annotations": {
                                        "alarms": [
                                                "${database_oraredo_read_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 12,
                        "y": 4,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Read Ops - Oracle",
                                "annotations": {
                                        "alarms": [
                                                "${database_oracle_read_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 12,
                        "y": 5,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Read Ops - Root",
                                "annotations": {
                                        "alarms": [
                                                "${database_root_read_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 18,
                        "y": 0,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Write Ops - Oradata",
                                "annotations": {
                                        "alarms": [
                                                "${database_oradata_writes_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 18,
                        "y": 1,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Write Ops - Oraarch",
                                "annotations": {
                                        "alarms": [
                                                "${database_oraarch_writes_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 18,
                        "y": 2,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Write Ops - Oratmp",
                                "annotations": {
                                        "alarms": [
                                                "${database_oratmp_writes_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 18,
                        "y": 3,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Write Ops - Oraredo",
                                "annotations": {
                                        "alarms": [
                                                "${database_oraredo_writes_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 18,
                        "y": 4,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Write Ops - Oracle",
                                "annotations": {
                                        "alarms": [
                                                "${database_oracle_writes_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 18,
                        "y": 5,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Write Ops - Root",
                                "annotations": {
                                        "alarms": [
                                                "${database_root_writes_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
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
                                "period": ${dashboard_refresh_period},
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
                                                "${cm_status_check_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
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
                                                "${app1_status_check_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
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
                                "period": ${dashboard_refresh_period},
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
                                "period": ${dashboard_refresh_period},
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
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": true
                        }
                },
                {
                        "type": "metric",
                        "x": 0,
                        "y": 8,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Swap Used",
                                "annotations": {
                                        "alarms": [
                                                "${database_ec2_swap_alarm}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": ${dashboard_refresh_period},
                                "region": "${aws_region}",
                                "stacked": true
                        }
                }
        ]
}
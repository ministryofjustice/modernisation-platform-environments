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
                        "y": 1,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EC2 Memory Usage",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rEc2MemoryOverThreshold}"
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
                        "y": 0,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EBS Disk Usage - Oradata",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rEbsDiskSpaceUsedOverThresholdOradata}"
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
                        "y": 1,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EBS Disk Usage - Oraarch",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rEbsDiskSpaceUsedOverThresholdOraarch}"
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
                        "y": 2,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EBS Disk Usage - Oratmp",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rEbsDiskSpaceUsedOverThresholdOratmp}"
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
                        "y": 3,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EBS Disk Usage - Oraredo",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rEbsDiskSpaceUsedOverThresholdOraredo}"
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
                        "y": 4,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EBS Disk Usage - Oracle",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rEbsDiskSpaceUsedOverThresholdOracle}"
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
                        "y": 5,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EBS Disk Usage - Root",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rEbsDiskSpaceUsedOverThresholdRoot}"
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
                        "x": 0,
                        "y": 3,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "EC2 RX Packets Dropped (${Ec2NetworkInterface})",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rNetworkRxDroppedPackets}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": "${dashboard_refresh_period}",
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
                                "title": "EC2 TX Packets Dropped (${Ec2NetworkInterface})",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rNetworkTxDroppedPackets}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": "${dashboard_refresh_period}",
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
                                "title": "EC2 RX Packet Errors (${Ec2NetworkInterface})",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rNetworkRxErrors}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": "${dashboard_refresh_period}",
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
                                "title": "EC2 TX Packet Errors (${Ec2NetworkInterface})",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rNetworkTxErrors}"
                                        ]
                                },
                                "view": "timeSeries",
                                "legend": {
                                        "position": "hidden"
                                },
                                "period": "${dashboard_refresh_period}",
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
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rVolumeReadsOverThresholdOradata}"
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
                        "y": 1,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Read Ops - Oraarch",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rVolumeReadsOverThresholdOraarch}"
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
                        "y": 2,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Read Ops - Oratmp",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rVolumeReadsOverThresholdOratmp}"
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
                        "y": 3,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Read Ops - Oraredo",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rVolumeReadsOverThresholdOraredo}"
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
                        "y": 4,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Read Ops - Oracle",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rVolumeReadsOverThresholdOracle}"
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
                        "y": 5,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Read Ops - Root",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rVolumeReadsOverThresholdRoot}"
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
                        "y": 0,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Write Ops - Oradata",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rVolumeWritesOverThresholdOradata}"
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
                        "y": 1,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Write Ops - Oraarch",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rVolumeWritesOverThresholdOraarch}"
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
                        "y": 2,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Write Ops - Oratmp",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rVolumeWritesOverThresholdOratmp}"
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
                        "y": 3,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Write Ops - Oraredo",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rVolumeWritesOverThresholdOraredo}"
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
                        "y": 4,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Write Ops - Oracle",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rVolumeWritesOverThresholdOracle}"
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
                        "y": 5,
                        "height": 5,
                        "width": 6,
                        "properties": {
                                "title": "Volume Write Ops - Root",
                                "annotations": {
                                        "alarms": [
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rVolumeWritesOverThresholdRoot}"
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
                                                "${cm_status_check_alarm}"
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
                                                "${app1_status_check_alarm}"
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
                                                "arn:aws:cloudwatch:${aws_region}:${AWS::AccountId}:alarm:${rSwapUsedOverThreshold}"
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
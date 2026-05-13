[
  {
    "name": "${app_name}",
    "image": "${app_image}:${container_version}",
    "cpu": ${cpu},
    "memory": ${memory},
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${app_name}-ecs",
          "awslogs-region": "${aws_region}",
          "awslogs-stream-prefix": "ecs"
        }
    },
    "portMappings": [
      {
        "containerPort": ${api_server_port},
        "hostPort": ${api_server_port}
      }
    ],
    "environment": [
      {
        "name": "CCMS_S3_BUCKET",
        "value": "${ccms_s3_bucket}"
      }
    ],
    "secrets": [
      {
        "name": "ebs_db_username",
        "valueFrom": "${ebs_db_username}"
      },
      {
        "name": "ebs_db_password",
        "valueFrom": "${ebs_db_password}"
      },
      {
        "name": "ebs_db_endpoint",
        "valueFrom": "${ebs_db_endpoint}"
      },
      {
        "name": "file_transfer_slack_webhook",
        "valueFrom": "${file_transfer_slack_webhook}"
      },
      {
        "name": "TLS_CERT",
        "valueFrom": "${TLS_CERT}"
      },
      {
        "name": "TLS_KEY",
        "valueFrom": "${TLS_KEY}"
      }
    ]
  }
]

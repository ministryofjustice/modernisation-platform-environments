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
      },
      {
        "name": "LOGGING_LEVEL_ROOT",
        "value": "${logging_level_root}"
      }
    ],
    "secrets": [
      {
        "name": "ORACLE_USERNAME",
        "valueFrom": "${ORACLE_USERNAME}"
      },
      {
        "name": "ORACLE_PASSWORD",
        "valueFrom": "${ORACLE_PASSWORD}"
      },
      {
        "name": "ORACLE_URL",
        "valueFrom": "${ORACLE_URL}"
      },
      {
        "name": "SLACK_WEBHOOK",
        "valueFrom": "${SLACK_WEBHOOK}"
      },
      {
        "name": "ENABLE_SWAGGER",
        "valueFrom": "${ENABLE_SWAGGER}"
      },
      {
        "name": "AUTHORIZED_CLIENTS",
        "valueFrom": "${AUTHORIZED_CLIENTS}"
      },
      {
        "name": "AUTHORIZED_ROLES",
        "valueFrom": "${AUTHORIZED_ROLES}"
      },
      {
        "name": "UNPROTECTED_URIS",
        "valueFrom": "${UNPROTECTED_URIS}"
      }
    ]
  }
]

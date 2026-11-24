[
  {
    "name": "${app_name}-container",
    "image": "${app_image}:${container_version}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group_name}",
        "awslogs-region": "${aws_region}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "portMappings": [
      {
        "containerPort": ${api_server_port}
      }
    ],
    "essential": true,
    "environment": [
      {
        "name": "CCMS_S3_BUCKET",
        "value": "${ccms_s3_bucket}"
      },
      {
        "name": "LOGGING_LEVEL_ROOT",
        "value": "${logging_level_root}"
      },
      {
        "name": "LOGGING_LEVEL_UK_GOV_LAA_CCMS",
        "value": "${logging_level_uk_gov_laa_ccms}"
      }
    ],
    "secrets": [
      {
        "name": "ORACLE_USERNAME",
        "valueFrom": "${oracle_username}"
      },
      {
        "name": "ORACLE_PASSWORD",
        "valueFrom": "${oracle_password}"
      },
      {
        "name": "ORACLE_URL",
        "valueFrom": "${oracle_url}"
      },
      {
        "name": "SLACK_WEBHOOK",
        "valueFrom": "${slack_webhook}"
      },
      {
        "name": "ENABLE_SWAGGER",
        "valueFrom": "${enable_swagger}"
      },
      {
        "name": "AUTHORIZED_CLIENTS",
        "valueFrom": "${authorized_clients}"
      },
      {
        "name": "AUTHORIZED_ROLES",
        "valueFrom": "${authorized_roles}"
      },
      {
        "name": "UNPROTECTED_URIS",
        "valueFrom": "${unprotected_uris}"
      },
      {
        "name": "OAUTH2_ISSUER_URI",
        "valueFrom": "${oauth2_issuer_uri}"
      },
      {
        "name": "OAUTH2_AUDIENCE",
        "valueFrom": "${oauth2_audience}"
      },
      {
        "name": "OAUTH2_ROLES",
        "valueFrom": "${oauth2_roles}"
      },
      {
        "name": "OAUTH2_UNPROTECTED_URIS",
        "valueFrom": "${oauth2_unprotected_uris}"
      },
      {
        "name": "TLS_KEYSTORE_PASSWORD",
        "valueFrom": "${tls_keystore_password}"
      }
    ]
  }
]

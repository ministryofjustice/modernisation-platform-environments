[
  {
    "name": "${app_name}-container",
    "image": "${app_image}:${container_version}",
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
        "containerPort": ${server_port}
      }
    ],
    "mountPoints": [
      {
        "containerPath": "/opa",
        "sourceVolume": "opa_volume"
      }
    ],
    "essential": true,
    "environment": [
      {
        "name": "DB_HOST",
        "value": "${db_host}"
      },
      {
        "name": "USER_MEM_ARGS",
        "value": "${wl_mem_args}"
      },
      {
        "name": "JAVA_TOOL_OPTIONS",
        "value": "-XX:MetaspaceSize=128M -XX:MaxMetaspaceSize=512M -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:InitiatingHeapOccupancyPercent=35 -XX:G1HeapRegionSize=16M -XX:MinMetaspaceFreeRatio=50 -XX:MaxMetaspaceFreeRatio=80 -XX:+AlwaysPreTouch"
      },
      {
        "name": "NON_SECURE_COOKIE",
        "value": "true"
      },
      {
        "name": "OPA_INSTANCE_NAME",
        "value": "opa"
      },
      {
        "name": "DOMAIN_NAME",
        "value": "base_domain"
      },
      {
        "name": "PRODUCTION_MODE",
        "value": "prod"
      },
      {
        "name": "ADMINISTRATION_PORT_ENABLED",
        "value": "false"
      },
      {
        "name": "CREATE_DATABASE",
        "value": "${create_database}"
      }
    ],
    "secrets": [
      {
        "name": "DB_PASSWORD",
        "valueFrom": "${db_password}"
      },
      {
        "name": "HUB_ADMIN_PASS",
        "valueFrom": "${opahub_password}"
      },
      {
        "name": "WL_PASSWORD",
        "valueFrom": "${wl_password}"
      },
      {
        "name": "SECRET_KEY",
        "valueFrom": "${secret_key}"
      },
      {
        "name": "DB_USER",
        "valueFrom": "${db_user}"
      },
      {
        "name": "WL_USER",
        "valueFrom": "${wl_user}"
      }
    ]
  }
]
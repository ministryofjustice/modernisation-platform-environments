[
  {
    "name": "${app_name}",
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
        "containerPort": ${app_port}
      }
    ],
    "essential": true,
    "environment": [
      {
        "name": "SPRING_PROFILES_ACTIVE",
        "value": "${spring_profiles}"
      },
      {
        "name": "SPRING_DATASOURCE_USERNAME",
        "value": "${db_username}"
      },
      {
        "name": "SPRING_DATASOURCE_URL",
        "value": "jdbc:mysql://${db_url}:3306/oia"
      },
      {
        "name": "LOGGING_LEVEL_ROOT",
        "value": "${logging_level}"
      }
    ],
    "secrets": [
      {
        "name": "SPRING_DATASOURCE_PASSWORD",
        "valueFrom": "${db_password}"
      }
    ]
  }
]

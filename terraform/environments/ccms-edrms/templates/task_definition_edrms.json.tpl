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
        "containerPort": ${edrms_server_port}
      }
    ],
    "essential": true,
    "environment": [
      {
        "name": "SPRING_PROFILES_ACTIVE",
        "value": "${spring_profiles_active}"
      },      
      {
        "name": "SPRING_DATASOURCE_USERNAME",
        "value": "${spring_datasource_username}"
      },
      {
        "name": "TARGET_NORTHGATE_HUB_DIME_URL",
        "value": "${target_northgate_hub_dime_url}"
      },
      {
        "name": "NORTHGATE_TIMEOUT",
        "value": "${northgate_timeout}"
      },
      {
        "name": "SPRING_DATASOURCE_URL",
        "value": "jdbc:oracle:thin:@${spring_datasource_url}/EDRMSTDS"
      },
      {
        "name": "logging_level_root",
        "value": "${logging_level_root}"
      }
    ],
    "secrets": [
        {
          "name": "SPRING_DATASOURCE_PASSWORD",
          "valueFrom": "${spring_datasource_password}"
        }
    ]
  }
]

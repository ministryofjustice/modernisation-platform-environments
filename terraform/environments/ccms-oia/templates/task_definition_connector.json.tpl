[
  {
    "name": "${connector_app_name}-container",
    "image": "${connector_ecr_repo}:${container_version}",
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${connector_app_name}-ecs",
          "awslogs-region": "${aws_region}",
          "awslogs-stream-prefix": "ecs"
        }
    },
    "portMappings": [
      {
        "containerPort": ${connector_server_port}
      }
    ],
    "essential": true,
    "environment": [
      {
        "name": "ccms_pui_connector_environmentId",
        "value": "${environment_connector}"
      },
      {
        "name": "ccms_soa_url_ebsReferenceDataEndpoint",
        "value": "${ccms_soa_url_ebsReferenceDataEndpoint}"
      },
      {
        "name": "ccms_pui_connector_assessservice_url_means",
        "value": "${ccms_pui_connector_assessservice_url_means}"
      },
      {
        "name": "ccms_pui_connector_assessservice_url_merits",
        "value": "${ccms_pui_connector_assessservice_url_merits}"
      },
      {
        "name": "ccms_pui_connector_assessservice_url_billing",
        "value": "${ccms_pui_connector_assessservice_url_billing}"
      },
      {
        "name": "ccms_pui_connector_answerservice_url_means",
        "value": "${ccms_pui_connector_answerservice_url_means}"
      },
      {
        "name": "ccms_pui_connector_answerservice_url_merits",
        "value": "${ccms_pui_connector_answerservice_url_merits}"
      },
      {
        "name": "ccms_pui_connector_answerservice_url_billing",
        "value": "${ccms_pui_connector_answerservice_url_billing}"
      },
      {
        "name": "AWS_REGION",
        "value": "${aws_region}"
      },
      {
        "name": "SPRING_PROFILES_ACTIVE",
        "value": "${spring_profiles_active}"
      },  
      {
        "name": "CCMS_S3_DOCUMENTS",
        "value": "${ccms_s3_documents}"
      },
      {
        "name": "AWS_ENDPOINT",
        "value": "${aws_endpoint}"
      },
      {
        "name": "LOGGING_LEVEL_ROOT",
        "value": "${logging_level_root}"
      },
      {
        "name": "LOGGING_LEVEL_COM_EZGOV_MODEL",
        "value": "${logging_level_com_ezgov_model}"
      },
      {
        "name": "LOGGING_LEVEL_COM_EZGOV_OPA",
        "value": "${logging_level_com_ezgov_opa}"
      },
      {
        "name": "LOGGING_LEVEL_ORACLE_OCS_OPA_LAA",
        "value": "${logging_level_oracle_ocs_opa_laa}"
      },
      {
        "name": "LOGGING_LEVEL_UK_GOV_LAA_OPA",
        "value": "${logging_level_uk_gov_laa_opa}"
      },
      {
        "name": "spring_datasource_hikari_keepalive-time",
        "value": "60000"
      }
    ],
    "secrets": [
      {
        "name": "ccms_soa_soapHeaderUserPassword",
        "valueFrom": "${ccms_soa_soapHeaderUserPassword}"
      },
      {
        "name": "ccms_connector_service_password",
        "valueFrom": "${ccms_connector_service_password}"
      },
      {
        "name": "spring_datasource_password",
        "valueFrom": "${spring_datasource_password}"
      },
      {
        "name": "ccms_pui_connector_assess_service_password",
        "valueFrom": "${client_opa12assess_security_user_password}"
      },
      {
        "name": "ccms_soa_soapHeaderUserName",
        "valueFrom": "${ccms_soa_soapHeaderUserName}"
      },
      {
        "name": "ccms_connector_service_userid",
        "valueFrom": "${ccms_connector_service_userid}"
      },
      {
        "name": "ccms_pui_connector_assess_service_userid",
        "valueFrom": "${client_opa12assess_security_user_name}"
      },
      {
        "name": "spring_datasource_url",
        "valueFrom": "${spring_datasource_url}"
      },
      {
        "name": "spring_datasource_username",
        "valueFrom": "${spring_datasource_username}"
      },
      {
        "name": "OPA_SECURITY_PASSWORD",
        "valueFrom": "${opa_security_password}"
      }
    ]
  }
]

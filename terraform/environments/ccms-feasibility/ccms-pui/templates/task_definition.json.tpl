[
  {
    "name": "${app_name}",
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
        "containerPort": ${pui_server_port},
        "hostPort": ${pui_server_port}
      }
    ],
    "essential": true,
    "environment": [
      {
        "name": "SPRING_DATASOURCE_HIKARI_KEEPALIVE-TIME",
        "value": "60000"
      },
      {
        "name": "SERVER_FORWARD_HEADERS_STRATEGY",
        "value": "framework"
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
        "name": "ccms_pui_feedback_url",
        "value": "${ccms_pui_feedback_url}"
      },
      {
        "name": "ccms_pui_owd_return_url",
        "value": "${ccms_pui_owd_return_url}"
      },
      {
        "name": "ccms_soa_url_ebsClientEndpoint",
        "value": "${ccms_soa_url_ebsClientEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsCaseEndpoint",
        "value": "${ccms_soa_url_ebsCaseEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsAddressEndpoint",
        "value": "${ccms_soa_url_ebsAddressEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsReferenceDataEndpoint",
        "value": "${ccms_soa_url_ebsReferenceDataEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsProviderRequestEndpoint",
        "value": "${ccms_soa_url_ebsProviderRequestEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsStatementOfAccountEndpoint",
        "value": "${ccms_soa_url_ebsStatementOfAccountEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsNotificationEndpoint",
        "value": "${ccms_soa_url_ebsNotificationEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsDocumentEndpoint",
        "value": "${ccms_soa_url_ebsDocumentEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsCreateInvoiceEndpoint",
        "value": "${ccms_soa_url_ebsCreateInvoiceEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsCoverSheetEndpoint",
        "value": "${ccms_soa_url_ebsCoverSheetEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsCommonOrgEndpoint",
        "value": "${ccms_soa_url_ebsCommonOrgEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsPrintInvoiceEndpoint",
        "value": "${ccms_soa_url_ebsPrintInvoiceEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsGetInvoiceDetailsEndpoint",
        "value": "${ccms_soa_url_ebsGetInvoiceDetailsEndpoint}"
      },
      {
        "name": "ccms_soa_url_ebsUpdateUserEndpoint",
        "value": "${ccms_soa_url_ebsUpdateUserEndpoint}"
      },
      {
        "name": "opa12_assess_service_servlet",
        "value": "${opa12_assess_service_servlet}"
      },
      {
        "name": "ccms_owd_rulebase_baseurl",
        "value": "${ccms_owd_rulebase_baseurl}"
      },
      {
        "name": "CCMS_PUI_AV_HOST",
        "value": "${ccms_pui_av_host}"
      },
      {
        "name": "JAVA_TOOL_OPTIONS",
        "value": "-XX:MetaspaceSize=128M -XX:MaxMetaspaceSize=512M -Xms4G -Xmx6G -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:InitiatingHeapOccupancyPercent=35 -XX:G1HeapRegionSize=16M -XX:MinMetaspaceFreeRatio=50 -XX:MaxMetaspaceFreeRatio=80 -XX:+AlwaysPreTouch"
      }
    ],
    "secrets": [
      {
        "name": "IDPCERT",
        "valueFrom": "${pui_secret_arn}:idp_cert::"
      },
      {
        "name": "SPCERT",
        "valueFrom": "${pui_secret_arn}:spcert::"
      },
      {
        "name": "SPPRIVATEKEY",
        "valueFrom": "${pui_secret_arn}:spprivatekey::"
      },
      {
        "name": "SPRING_DATASOURCE_USERNAME",
        "valueFrom": "${pui_secret_arn}:spring_datasource_username::"
      },
      {
        "name": "SPRING_DATASOURCE_PASSWORD",
        "valueFrom": "${pui_secret_arn}:spring_datasource_password::"
      },
      {
        "name": "SPRING_DATASOURCE_URL",
        "valueFrom": "${pui_secret_arn}:spring_datasource_url::"
      },
      {
        "name": "POSTCODEAPIKEY",
        "valueFrom": "${pui_secret_arn}:postcodeApiKey::"
      },
      {
        "name": "POSTCODEAPIURL",
        "valueFrom": "${pui_secret_arn}:postcodeApiUrl::"
      },
      {
        "name": "ccms_soa_soapHeaderUserName",
        "valueFrom": "${pui_secret_arn}:ccms_soa_soapHeaderUserName::"
      },
      {
        "name": "ccms_soa_soapHeaderUserPassword",
        "valueFrom": "${pui_secret_arn}:ccms_soa_soapHeaderUserPassword::"
      },
      {
        "name": "USER_MANAGEMENT_API_ACCESS_TOKEN",
        "valueFrom": "${pui_secret_arn}:user_management_api_access_token::"
      },
      {
        "name": "USER_MANAGEMENT_API_HOSTNAME",
        "valueFrom": "${pui_secret_arn}:user_management_api_hostname::"
      },
      {
        "name": "IDPMETADATAURL",
        "valueFrom": "${pui_secret_arn}:idpMetadataUrl::"
      },
      {
        "name": "IDPENTITYID",
        "valueFrom": "${pui_secret_arn}:idpIdentityID::"
      },
      {
        "name": "SPENTITYID",
        "valueFrom": "${pui_secret_arn}:SpEntityId::"
      },
      {
        "name": "SPENTITYURL",
        "valueFrom": "${pui_secret_arn}:SpEntityUrl::"
      },
      {
        "name": "LOGINURL",
        "valueFrom": "${pui_secret_arn}:loginUrl::"
      },
      {
        "name": "OPA_SECURITY_PASSWORD",
        "valueFrom": "${pui_secret_arn}:opa_security_password::"
      },
      {
        "name": "SPRING_PROFILES_ACTIVE",
        "valueFrom": "${pui_secret_arn}:spring_profiles_active::"
      },
      {
        "name": "IDPLOGOUTURL",
        "valueFrom": "${pui_secret_arn}:idpLogoutUrl::"
      },
      {
        "name": "IDPSAMLMOCKENABLED",
        "valueFrom": "${pui_secret_arn}:IdpSamlMockEnabled::"
      },
      {
        "name": "ENTRA_CUSTOM_USER_ID_CLAIM",
        "valueFrom": "${pui_secret_arn}:entra_custom_user_id_claim::"
      },
      {
        "name": "IS_SILAS_ENABLED",
        "valueFrom": "${pui_secret_arn}:is_silas_enabled::"
      },
      {
        "name": "ccms_soa_url_ebsContractDetailsEndpoint",
        "valueFrom": "${pui_secret_arn}:ccms_soa_url_ebsContractDetailsEndpoint::"
      },
      {
        "name": "ccms_soa_url_opaBillingAssessmentEndpoint",
        "valueFrom": "${pui_secret_arn}:ccms_soa_url_opaBillingAssessmentEndpoint::"
      },
      {
        "name": "ccms_soa_url_opaPOAAssessmentEndpoint",
        "valueFrom": "${pui_secret_arn}:ccms_soa_url_opaPOAAssessmentEndpoint::"
      },
      {
        "name": "CCMS_PUI_AV_PORT",
        "valueFrom": "${pui_secret_arn}:ccms_pui_av_port::"
      },
      {
        "name": "CCMS_PUI_AV_SOCKETTIMEOUT",
        "valueFrom": "${pui_secret_arn}:ccms_pui_av_socketTimeout::"
      },
      {
        "name": "CCMS_PUI_AV_SCANNERENABLED",
        "valueFrom": "${pui_secret_arn}:ccms_pui_av_scannerEnabled::"
      },
      {
        "name": "CCMS_PUI_AUDITLOGIN_ENABLED",
        "valueFrom": "${pui_secret_arn}:ccms_pui_auditLogin_enabled::"
      },
      {
        "name": "LOGGING_LEVEL_ROOT",
        "valueFrom": "${pui_secret_arn}:logging_level_root::"
      },
      {
        "name": "LOGGING_LEVEL_COM_EZGOV",
        "valueFrom": "${pui_secret_arn}:logging_level_com_ezgov::"
      },
      {
        "name": "LOGGING_LEVEL_COM_LEGALSERVICES",
        "valueFrom": "${pui_secret_arn}:logging_level_com_legalservices::"
      },
      {
        "name": "LOGGING_LEVEL_UK_GOV_LAA_OPA",
        "valueFrom": "${pui_secret_arn}:logging_level_uk_gov_laa_opa::"
      },
      {
        "name": "LOGGING_LEVEL_COM_EZGOV_ROOF_VIEW_VIM_CONTROL_BUNDLEAWARETEXT",
        "valueFrom": "${pui_secret_arn}:logging_level_com_ezgov_roof_view_vim_control_BundleAwareText::"
      }
    ]
  }
]

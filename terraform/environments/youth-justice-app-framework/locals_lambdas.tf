locals {
  split-ds-managed-ad-ips             = tolist(module.ds.dns_ip_addresses)
  s3-cross-account-replication-s3-arn = "arn:aws:s3:::redshift-serverless-yjb-${local.environment}-reporting"
  update-dc-names = {
    function_zip_file = "lambda_code/update-dc-names.zip"
    function_name     = "update-dc-names"
    handler           = "update_dc_names.lambda_handler"
    iam_role_name     = "update-dc-names-lambda-role"
    environment_variables = {
      LOG_GROUP_NAME = module.ds.cloudwatch_log_group_name
      LOG_STREAMS    = "${local.split-ds-managed-ad-ips[0]}-SecurityEvents,${local.split-ds-managed-ad-ips[1]}-SecurityEvents"
      SECRET_NAME    = aws_secretsmanager_secret.LDAP_DC_secret.name
    }
  }

  s3-cross-account-replication = {
    function_zip_file  = "lambda_code/s3-cross-account-replication.zip"
    function_name      = "s3-cross-account-replication"
    handler            = "s3-cross-account-replication.lambda_handler"
    iam_role_name      = "s3-cross-account-replication-lambda-role"
    lambda_memory_size = 512
    lambda_timeout     = 900
  }

  serverlessrepo-lambda-canary = {
    function_zip_file = "lambda_code/serverlessrepo-lambda-canary.zip"
    function_name     = "serverlessrepo-lambda-canary"
    handler           = "serverlessrepo-lambda-canary.lambda_handler"
    iam_role_name     = "serverlessrepo-lambda-canary-lambda-role"
    environment_variables = {
      expected = "UP"
      site_1   = "http://auth.${local.environment}.yjaf:8080/actuator/health"        #auth
      site_11  = "http://placements.${local.environment}.yjaf:8080/actuator/health"  #placements
      site_12  = "http://refdata.${local.environment}.yjaf:8080/actuator/health"     #refdata
      site_13  = "http://returns.${local.environment}.yjaf:8080/actuator/health"     #returns
      site_14  = "http://sentences.${local.environment}.yjaf:8080/actuator/health"   #sentences
      site_15  = "http://transfers.${local.environment}.yjaf:8080/actuator/health"   #transfers
      site_17  = "http://views.${local.environment}.yjaf:8080/actuator/health"       #views
      site_18  = "http://workflow.${local.environment}.yjaf:8080/actuator/health"    #workflow
      site_19  = "http://yp.${local.environment}.yjaf:8080/actuator/health"          #yp
      site_2   = "http://bands.${local.environment}.yjaf:8080/actuator/health"       #bands
      site_3   = "http://bu.${local.environment}.yjaf:8080/actuator/health"          #bu
      site_4   = "http://case.${local.environment}.yjaf:8080/actuator/health"        #case
      site_5   = "http://cmm.${local.environment}.yjaf:8080/actuator/health"         #cmm
      site_6   = "http://conversions.${local.environment}.yjaf:8080/actuator/health" #conversions
      site_8   = "http://dal.${local.environment}.yjaf:8080/actuator/health"         #dal
      site_9   = "http://documents.${local.environment}.yjaf:8080/actuator/health"   #documents
    }
    vpc_config = {
      subnet_ids         = local.private_subnet_list[*].id
      security_group_ids = [module.serverlessrepo-lambda-canary-sg.security_group_id]
    }
  }


  update-dc-names-role = {
    name              = "update-dc-names-lambda-role"
    trust_policy_path = "lambda_policies/lambda-role-trust.json"
    iam_policy_path   = "lambda_policies/update-dc-names-role-policy.json"
    policy_template_vars = {
      ldap_urls_secret_arn = aws_secretsmanager_secret.LDAP_DC_secret.arn
      account_number       = local.environment_management.account_ids[terraform.workspace]
    }
  }

  s3-cross-account-replication-role = {
    name              = "s3-cross-account-replication-lambda-role"
    trust_policy_path = "lambda_policies/lambda-role-trust.json"
    iam_policy_path   = "lambda_policies/s3-cross-account-replication-role-policy.json"
    policy_template_vars = {
      account_number = local.environment_management.account_ids[terraform.workspace]
    }
  }

  serverlessrepo-lambda-canary-role = {
    name              = "serverlessrepo-lambda-canary-lambda-role"
    trust_policy_path = "lambda_policies/lambda-role-trust.json"
    iam_policy_path   = "lambda_policies/serverlessrepo-lambda-canary-role-policy.json"
    policy_template_vars = {
      account_number = local.environment_management.account_ids[terraform.workspace]
    }
  }
}

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
    handler           = "lambda_function.lambda_handler"
    iam_role_name     = "serverlessrepo-lambda-canary-lambda-role"
    log_group = {
      name = "/aws/lambda/serverlessrepo-lambda-canary"
    }
    environment_variables = {
      url      = "http://private-lb.${local.environment}.yjaf:8080/actuator/health" # URL for the health endpoint
      expected = "UP"
      site_1   = "auth"        #auth
      site_11  = "placements"  #placements
      site_12  = "refdata"     #refdata
      site_13  = "returns"     #returns
      site_14  = "sentences"   #sentences
      site_15  = "transfers"   #transfers
      site_17  = "views"       #views
      site_18  = "workflow"    #workflow
      site_19  = "yp"          #yp
      site_2   = "bands"       #bands
      site_3   = "bu"          #bu
      site_4   = "case"        #case
      site_5   = "cmm"         #cmm
      site_6   = "conversions" #conversions
      site_8   = "dal"         #dal
      site_9   = "documents"   #documents
    }
    vpc_config = {
      subnet_ids         = local.private_subnet_list[*].id
      security_group_ids = [module.serverlessrepo-lambda-canary-sg.security_group_id]
    }
  }

  inspector-sbom-ec2 = {
    function_zip_file = "lambda_code/inspector-sbom-ec2.zip"
    function_name     = "inspector-sbom-ec2"
    handler           = "inspector-sbom-ec2.lambda_handler"
    iam_role_name     = "inspector-sbom-ec2-lambda-role"
    environment_variables = {
      S3_BUCKET   = module.s3-sbom.aws_s3_bucket_id["application-sbom"].id
      KMS_KEY_ARN = module.kms.key_arn
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

  inspector-sbom-ec2-role = {
    name              = "inspector-sbom-ec2-lambda-role"
    trust_policy_path = "lambda_policies/lambda-role-trust.json"
    iam_policy_path   = "lambda_policies/inspector-sbom-ec2-role-policy.json"
    policy_template_vars = {
      aws_s3_bucket_sbom_arn = module.s3-sbom.aws_s3_bucket["application-sbom"].arn
      aws_kms_key_sbom_arn   = module.kms.key_arn
    }
  }
}

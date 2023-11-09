#### This file can be used to store locals specific to the member account ####
locals {

  #Lambda files
  dbsnapshot_source_file     = "dbsnapshot.js"
  deletesnapshot_source_file = "deletesnapshots.py"
  dbconnect_source_file      = "dbconnect.js"
  
  dbsnapshot_output_path     = "dbsnapshot.zip"
  deletesnapshot_output_path = "deletesnapshots.zip"
  dbconnect_output_path      = "dbconnect.zip"

  #Lambda Function creation
  snapshotDBFunctionname     = "snapshotDBFunction"
  snapshotDBFunctionhandler  = "snapshot/dbsnapshot.handler"
  snapshotDBFunctionruntime  = "nodejs18.x"
  snapshotDBFunctionfilename = "dbsnapshot.zip"

  deletesnapshotFunctionname     = "deletesnapshotFunction"
  deletesnapshotFunctionhandler  = "deletesnapshots.lambda_handler"
  deletesnapshotFunctionruntime  = "python3.8"
  deletesnapshotFunctionfilename = "deletesnapshots.zip"

  connectDBFunctionname     = "connectDBFunction"
  connectDBFunctionhandler  = "ssh/dbconnect.handler"
  connectDBFunctionruntime  = "nodejs18.x"
  connectDBFunctionfilename = "dbconnect.zip"

  #layer config
  s3layerkey          = "nodejs.zip"
  compatible_runtimes = "nodejs18.x"

  application_test_url = "https://apex.laa-development.modernisation-platform.service.justice.gov.uk/apex/"

  ecs_target_capacity = 100

  # ECS local variables for ecs.tf
  ec2_ingress_rules = {
    "cluster_ec2_lb_ingress_3" = {
      description     = "Cluster EC2 ingress rule 3"
      from_port       = 32768
      to_port         = 61000
      protocol        = "tcp"
      cidr_blocks     = []
      # Update the below SG to mention ALB SG
      security_groups = []
    }
  }
  ec2_egress_rules = {
    "cluster_ec2_lb_egress" = {
      description     = "Cluster EC2 loadbalancer egress rule"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }

  user_data = base64encode(templatefile("user_data.sh", {
    app_name = local.application_name
  }))

  task_definition = templatefile("task_definition.json", {
    app_name            = local.application_name
    ecr_url             = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/apex-ecr-repo"
    docker_image_tag    = local.application_data.accounts[local.environment].docker_image_tag
    region              = local.application_data.accounts[local.environment].region
    app_db_url          = local.application_data.accounts[local.environment].app_db_url
    app_debug_enabled   = local.application_data.accounts[local.environment].app_debug_enabled
    db_secret_arn       = "arn:aws:ssm:${local.application_data.accounts[local.environment].region}:${local.env_account_id}:parameter/${local.app_db_password_name}"
  })

  env_account_id       = local.environment_management.account_ids[terraform.workspace]
  app_db_password_name = "APP_APEX_DBPASSWORD_TAD"
}

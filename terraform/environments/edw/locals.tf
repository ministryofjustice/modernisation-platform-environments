#### This file can be used to store locals specific to the member account ####
locals {

  database_ec2_name = "${local.application_name} Database Server"

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

  application_test_url = "https://edw.laa-development.modernisation-platform.service.justice.gov.uk/edw/"

  ecs_target_capacity = 100
}
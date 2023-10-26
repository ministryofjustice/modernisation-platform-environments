#### This file can be used to store locals specific to the member account ####
locals {

  #Lambda files
  dbsnapshot_source_file = "dbsnapshot.js"
  deletesnapshot_source_file = "deletesnapshots.py"
  dbconnect_source_file = "dbconnect.js"
  
  dbsnapshot_output_path = "dbsnapshot.zip"
  deletesnapshot_output_path = "deletesnapshots.zip"
  dbconnect_output_path = "dbconnect.zip"

  #Lambda Function creation
  snapshotDBFunctionname = "snapshotDBFunction"
  snapshotDBFunctionhandler = "snapshot/dbsnapshot.handler"
  snapshotDBFunctionruntime = "nodejs14.x"
  snapshotDBFunctionfilename = "dbsnapshot.zip"

  deletesnapshotFunctionname = "deletesnapshotFunction"
  deletesnapshotFunctionhandler = "deletesnapshots.lambda_handler"
  deletesnapshotFunctionruntime = "python3.8"
  deletesnapshotFunctionfilename = "deletesnapshots.zip"

  connectDBFunctionname = "connectDBFunction"
  connectDBFunctionhandler = "ssh/dbconnect.handler"
  connectDBFunctionruntime = "nodejs14.x"
  connectDBFunctionfilename = "dbconnect.zip"

  #layer config
  s3layerkey = "nodejs.zip"
  compatible_runtimes = "nodejs14.x"

  application_test_url = "https://apex.laa-development.modernisation-platform.service.justice.gov.uk/apex/"
}
#### This file can be used to store locals specific to the member account ####
locals {
  #js FIles
  dbsourcefiles = var.source_file
  #ZIP FILES Below
  zipfiles = var.output_path
  #Functions
 functions = var.function_name
  #Handlers
  handlers = var.handler
  #Runtime
  runtime = var.runtime

  key = var.key
  #Lambda Config
  dbsnapshot_source_file = "dbsnapshot.js"
  deletesnapshot_source_file = "deletesnapshots.py"
  dbconnect_source_file = "dbconnect.js"
  dbsnapshot_output_path = "dbsnapshot.zip"
  deletesnapshot_output_path = "deletesnapshots.zip"
  dbconnect_output_path = "dbconnect.zip"

  snapshotDBFunctionname = "snapshotDBFunction"
  snapshotDBFunctionhandler = "snapshot/dbsnapshot.handler"
  snapshotDBFunctionruntime = "nodejs18.x"
  snapshotDBFunctionfilename = "dbsnapshot.zip"


  deletesnapshotFunctionname = "deletesnapshotFunction"
  deletesnapshotFunctionhandler = "deletesnapshots.lambda_handler"
  deletesnapshotFunctionruntime = "python3.8"
  deletesnapshotFunctionfilename = "deletesnapshots.zip"


  connectDBFunctionname = "connectDBFunction"
  connectDBFunctionhandler = "ssh/dbconnect.handler"
  connectDBFunctionruntime = "nodejs18.x"
  connectDBFunctionfilename = "dbconnect.zip"



  application_test_url = "https://apex.laa-development.modernisation-platform.service.justice.gov.uk/apex/"
}
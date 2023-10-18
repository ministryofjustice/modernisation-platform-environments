#### This file can be used to store locals specific to the member account ####
locals {
  #js FIles
  dbsourcefiles = var.source_file
 
  
  #ZIP FILES Below
  zipfiles = var.output_path

  #Functions
 functions = var.function_name

  #Handlers
  dbsnaphandler= "snapshot/dbsnapshot.handler"
  deletesnaphandler= "deletesnapshots.lambda_handler"
  connecthandler= "ssh/dbconnect.handler"

  #Runtime
  nodejsversion= "nodejs18.x"
  pythonversion= "python3.8"




}
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

  application_test_url = "https://apex.laa-development.modernisation-platform.service.justice.gov.uk/apex/"
}
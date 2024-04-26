locals {
    path_to_lambda = "lambdas/validation"
}

resource "null_resource" "layer_file" {
 
#   triggers = {
#     value = filebase64sha256("${locals.path_to_lambda}/requirements.txt")
#   }
 
  provisioner "local-exec" {
    command = <<EOT
        cd ${locals.path_to_lambda}
        rm /python
        mkdir /python
        pip install -r /requirements.txt --target ./python
        zip -r layer.zip python/
    EOT
  }
}

resource "aws_lambda_layer" "validation_job_layer" {
    filename = "${path_to_lambda}/layer.zip"
    layer_name = "validation-job"
    compatible_runtimes = ["python3.10"]
    source_code_hash = filebase64sha256("${locals.path_to_lambda}/layer.zip")
    depends_on = [null_resource.layer_file]
}
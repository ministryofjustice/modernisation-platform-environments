locals {
    path_to_lambda = "lambdas/semantic_layer"
}

resource "null_resource" "semantic_layer_layer_file" {
 
#   triggers = {
#     value = filebase64sha256("${locals.path_to_lambda}/requirements.txt")
#   }
 
  provisioner "local-exec" {
    command = <<EOT
        cd ${local.path_to_lambda}
        rm /python
        mkdir /python
        pip install -r /requirements.txt --target ./python
        zip -r layer.zip python/
    EOT
  }
}

resource "aws_iam_role" "semantic_layer" {
    name = "semantic_layer_lambda"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy_document" "semantic_layer" {
    statement {
      # effect = "Allow"
      # principals {
      #   type = "Service"
      #   identifiers = ["lambda.amazonaws.com"]
      # }
      # actions = ["sts:AssumeRole"]
    }
}


data "archive_file" "semantic_layer_lambda" {
  type        = "zip"
  source_file = "${local.path_to_lambda}/semantic_layer.py"
  output_path = "${local.path_to_lambda}/semantic_layer.zip"
}


resource "aws_lambda_layer" "semantic_layer" {
    filename = "${path_to_lambda}/layer.zip"
    layer_name = "semantic-layer"
    compatible_runtimes = ["python3.10"]
    source_code_hash = filebase64sha256("${locals.path_to_lambda}/layer.zip")
    depends_on = [null_resource.layer_file]
}

resource "aws_lambda_function" "semantic_layer" {
    filename = "${local.path_to_lambda}/semantic_layer.zip"
    function_name = "semantic_layer"
    role = aws_iam_role.semantic_layer.name
    handler = "validatoin_job.handler"
    source_code_hash = data.archive_file.semantic_layer_lambda.output_base64sha256
    runtime = "python3.10"
    environment {
      variables = {
        one = 1
      }
    }

}
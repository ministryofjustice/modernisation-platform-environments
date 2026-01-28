# resource "null_resource" "build_lambda_zip" {

#   triggers = {
#     script_hash = filesha256("${path.module}/lambdas/rag-lambda/rag-lambda.py")
#   }

#   provisioner "local-exec" {
#     command = <<-EOT
#       cd ${path.module}/lambdas/rag-lambda

#       zip -r rag-lambda.zip .
#     EOT
#   }
# }

data "archive_file" "rag_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/rag-lambda/"
  output_path = "${path.module}/lambdas/rag-lambda.zip"
}
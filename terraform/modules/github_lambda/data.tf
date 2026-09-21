resource "terraform_data" "lambda_build" {
  triggers_replace = [
    filesha256("${path.module}/lambda/handler.py"),
    filesha256("${path.module}/lambda/requirements.txt"),
  ]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      rm -rf "${path.module}/build"
      mkdir -p "${path.module}/build/package"
      python3 -m pip install \
        --quiet \
        --requirement "${path.module}/lambda/requirements.txt" \
        --target "${path.module}/build/package"
      cp "${path.module}/lambda/handler.py" "${path.module}/build/package/handler.py"
      cd "${path.module}/build/package"
      zip -qr "${path.module}/build/github-workflow-trigger.zip" .
    EOT
  }
}

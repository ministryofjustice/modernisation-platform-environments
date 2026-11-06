resource "terraform_data" "lambda_build" {
  triggers_replace = [
    filesha256("${path.module}/lambda/handler.py"),
    filesha256("${path.module}/lambda/requirements.txt"),
  ]

  provisioner "local-exec" {
    working_dir = path.module
    command     = <<-EOT
      set -e
      rm -rf build
      mkdir -p build/package
      python3 -m pip install \
        --quiet \
        --requirement "lambda/requirements.txt" \
        --target "build/package"
      cp "lambda/handler.py" "build/package/handler.py"
      cd "build/package"
      zip -qr "../github-workflow-trigger.zip" .
    EOT
  }
}

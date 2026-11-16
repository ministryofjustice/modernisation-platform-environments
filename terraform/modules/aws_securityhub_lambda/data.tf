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
      zip -qr "../securityhub-finding-issue.zip" .
    EOT
  }
}

data "aws_ssm_parameter" "aws_accounts" {
  name = var.aws_accounts_parameter_name
}

data "aws_ssm_parameter" "securityhub_ignore_findings" {
  name = var.securityhub_ignore_findings_parameter_name
}

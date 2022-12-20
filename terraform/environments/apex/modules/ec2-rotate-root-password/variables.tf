variable "application_name" {}

variable "aws_account_id" {}

variable "secret_id_suffix_length" { default = "3" }

variable "secret_rotation_frequency_days" { default = "28" }

variable "lambda_function_name" { default = "system-root-password-rotation" }

variable "lambda_function_description" { default = "Rotate AWS Secrets Manager Secret Value" }

variable "lambda_function_runtime" { default = "python3.8" }

variable "lambda_function_handler" { default = "index.lambda_handler" }

variable "lambda_function_timeout" { default = "300" }

variable "lambda_function_inline_code_filename" { default = "index.py" }

variable "tags" {}

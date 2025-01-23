locals {

  bucket_name = formatlist("${var.environment_name}-%s", var.bucket_name)

}

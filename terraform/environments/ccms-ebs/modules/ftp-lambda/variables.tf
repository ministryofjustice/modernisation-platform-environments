
variable "lambda_name" {}
variable "vpc_id" {}
variable "subnet_ids" {
  type = list(string)
}
variable "ftp_port" {
  default = "22"
}
variable "ftp_protocol" {
  default = "SFTP"
}
variable "ftp_transfer_type" {}
variable "ftp_file_types" {
  default = ""
}
variable "ftp_local_path" {}
variable "ftp_remote_path" {}
variable "ftp_require_ssl" {
  default = "NO"
}
variable "ftp_ca_cert" {
  default = ""
}
variable "ftp_cert" {
  default = ""
}
variable "ftp_key" {
  default = ""
}
variable "ftp_key_type" {
  default = ""
}
variable "skip_key_verification" {
  default = "YES"
}
variable "ftp_file_remove" {
  default = "YES"
}
variable "ftp_cron" {
  default = "cron(0 10 * * ? *)"
}
variable "ftp_bucket" {}
variable "secret_name" {}
variable "env" {}
variable "secret_arn" {}
variable "s3_bucket_ftp" {}
variable "s3_bucket_layer_ftp" {}
variable "s3_object_ftp_client" {}
variable "s3_object_ftp_clientlibs" {}

variable "lambda_memory" {
  default = "4096"
}

variable "lambda_storage" {
  default = "1024"
}
variable "enabled_cron_in_environments" {
  description = "List of environments where cron should be enabled"
  type        = list(string)
  default     = ["development", "test", "perproduction"]
}
variable "networking" {
  type = list(any)
}

variable "collaborator_access" {
  type        = string
  default     = "developer"
  description = "Collaborators must specify which access level they are using, eg set an environment variable of export TF_VAR_collaborator_access=migration"
}

variable "transfer_ftps_certificate_arn" {
  type        = string
  description = "ACM certificate ARN used by the AWS Transfer FTPS endpoint."

  validation {
    condition     = can(regex("^arn:aws:acm:eu-west-2:[0-9]{12}:certificate/[0-9a-f-]+$", var.transfer_ftps_certificate_arn))
    error_message = "transfer_ftps_certificate_arn must be an ACM certificate ARN in eu-west-2."
  }
}

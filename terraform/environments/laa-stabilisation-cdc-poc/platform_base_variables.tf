variable "networking" {

  type = list(any)

}

variable "collaborator_access" {
  type        = string
  default     = "developer"
  description = "Collaborators must specify which access level they are using, eg set an environment variable of export TF_VAR_collaborator_access=migration"
}

variable "manage_backup_lambda_integration" {
  type        = bool
  default     = false
  description = "Whether Terraform manages the manually created backup Lambda EventBridge integration"
}

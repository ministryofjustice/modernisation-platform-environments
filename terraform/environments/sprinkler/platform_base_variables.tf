variable "networking" {

  type = list(any)

}

variable "collaborator_access" {
  type        = string
  default     = "developer"
  description = "Collaborators must specify which access level they are using, eg set an environment variable of export TF_VAR_collaborator_access=migration"
}

variable "identity_provider_instance_arn" {
  description = "The instance ARN for Transfer Family identity provider"
  type        = string
}

variable "identity_provider_role_arn" {
  description = "The IAM role ARN for the identity provider"
  type        = string
}
variable "networking" {
  type = list(any)
}

variable "collaborator_access" {
  type        = string
  default     = "developer"
  description = "Collaborators must specify which access level they are using, eg set an environment variable of export TF_VAR_collaborator_access=migration"
}

variable "athena_query_principal_arns" {
  type        = set(string)
  description = "IAM or SSO role ARNs allowed to assume the GitHub audit log query role"
}

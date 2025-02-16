variable "networking" {

  type = list(any)

}

#####

variable "collaborator_access" {
  type        = string
  default     = "developer"
  description = "Collaborators must specify which access level they are using, eg set an environment variable of export TF_VAR_collaborator_access=migration"
}



variable "dms_kms_source_cmk" {
  default = null
  description = "The ARN of the KMS Key to use when encrypting data for DMS source endpoint"
  type = object({
    arn = string
  })
}


variable "networking" {

  type = list(any)

}

variable "collaborator_access" {
  type        = string
  default     = "developer"
  description = "Collaborators must specify which access level they are using"
}
